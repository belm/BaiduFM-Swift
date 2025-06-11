//
//  DownloadManager.swift
//  BaiduFM
//
//  下载管理器 - 支持多任务下载、断点续传、下载队列管理
//  提供完整的音频文件下载和本地存储功能
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

// MARK: - 下载状态枚举
enum DownloadStatus {
    case waiting     // 等待下载
    case downloading // 下载中
    case paused      // 已暂停
    case completed   // 下载完成
    case failed      // 下载失败
    case cancelled   // 已取消
}

// MARK: - 下载任务模型
class DownloadTask {
    let id: String
    let song: Song
    let url: URL
    let destinationURL: URL
    
    // 响应式属性
    let status = BehaviorRelay<DownloadStatus>(value: .waiting)
    let progress = BehaviorRelay<Float>(value: 0.0)
    let downloadedSize = BehaviorRelay<Int64>(value: 0)
    let totalSize = BehaviorRelay<Int64>(value: 0)
    let speed = BehaviorRelay<String>(value: "0 KB/s")
    let error = BehaviorRelay<Error?>(value: nil)
    
    // 内部属性
    var downloadRequest: DownloadRequest?
    var startTime: Date?
    
    init(song: Song, url: URL, destinationURL: URL) {
        self.id = song.sid
        self.song = song
        self.url = url
        self.destinationURL = destinationURL
    }
}

// MARK: - 下载管理器
class DownloadManager {
    
    // MARK: - 单例
    static let shared = DownloadManager()
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private let session: Session
    private let fileManager = FileManager.default
    private let maxConcurrentDownloads = 3
    
    // MARK: - 公共响应式属性
    let downloadTasks = BehaviorRelay<[DownloadTask]>(value: [])
    let activeDownloads = BehaviorRelay<Int>(value: 0)
    let totalDownloadsCount = BehaviorRelay<Int>(value: 0)
    let completedDownloadsCount = BehaviorRelay<Int>(value: 0)
    
    // MARK: - 下载目录路径
    lazy var downloadsDirectory: URL = {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let downloadsPath = documentsPath.appendingPathComponent("Downloads")
        
        // 创建下载目录
        try? fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true, attributes: nil)
        
        return downloadsPath
    }()
    
    // MARK: - 初始化
    private init() {
        // 配置下载会话
        let configuration = URLSessionConfiguration.background(withIdentifier: "com.baidufm.download")
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 3600 // 1小时
        configuration.allowsCellularAccess = true
        
        self.session = Session(configuration: configuration)
        
        setupBindings()
        loadExistingDownloads()
    }
    
    // MARK: - 设置数据绑定
    private func setupBindings() {
        // 监听下载任务变化，更新统计信息
        downloadTasks
            .map { tasks in tasks.filter { $0.status.value == .downloading }.count }
            .bind(to: activeDownloads)
            .disposed(by: disposeBag)
        
        downloadTasks
            .map { $0.count }
            .bind(to: totalDownloadsCount)
            .disposed(by: disposeBag)
        
        downloadTasks
            .map { tasks in tasks.filter { $0.status.value == .completed }.count }
            .bind(to: completedDownloadsCount)
            .disposed(by: disposeBag)
    }
    
    // MARK: - 加载已存在的下载任务
    private func loadExistingDownloads() {
        // 扫描下载目录，加载已完成的下载
        do {
            let downloadedFiles = try fileManager.contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in downloadedFiles {
                if fileURL.pathExtension.lowercased() == "mp3" {
                    // 尝试从文件名解析歌曲信息
                    if let song = parseSongFromFilename(fileURL.lastPathComponent) {
                        let task = DownloadTask(song: song, url: URL(string: song.song_url)!, destinationURL: fileURL)
                        task.status.accept(.completed)
                        task.progress.accept(1.0)
                        
                        // 获取文件大小
                        if let fileSize = try? fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 {
                            task.totalSize.accept(fileSize)
                            task.downloadedSize.accept(fileSize)
                        }
                        
                        addTaskToList(task)
                    }
                }
            }
        } catch {
            print("加载已存在下载失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 开始下载
    func startDownload(song: Song) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            // 检查是否已存在该下载任务
            if let existingTask = self.findTask(by: song.sid) {
                if existingTask.status.value == .completed {
                    observer.onError(DownloadError.alreadyExists)
                    return Disposables.create()
                } else if existingTask.status.value == .downloading {
                    observer.onCompleted() // 已在下载中
                    return Disposables.create()
                }
            }
            
            // 创建下载任务
            guard let url = URL(string: song.song_url) else {
                observer.onError(DownloadError.invalidURL)
                return Disposables.create()
            }
            
            let filename = self.generateFilename(for: song)
            let destinationURL = self.downloadsDirectory.appendingPathComponent(filename)
            
            let task = DownloadTask(song: song, url: url, destinationURL: destinationURL)
            self.addTaskToList(task)
            
            // 开始下载
            self.performDownload(task: task) { result in
                switch result {
                case .success:
                    observer.onCompleted()
                case .failure(let error):
                    observer.onError(error)
                }
            }
            
            return Disposables.create {
                // 取消下载
                self.cancelDownload(taskId: task.id)
            }
        }
    }
    
    // MARK: - 执行下载
    private func performDownload(task: DownloadTask, completion: @escaping (Result<Void, Error>) -> Void) {
        // 检查并发下载限制
        guard activeDownloads.value < maxConcurrentDownloads else {
            task.status.accept(.waiting)
            return
        }
        
        task.status.accept(.downloading)
        task.startTime = Date()
        
        // 配置下载目标
        let destination: DownloadRequest.Destination = { _, _ in
            return (task.destinationURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        // 开始下载
        let downloadRequest = session.download(task.url, to: destination)
            .downloadProgress { [weak task] progress in
                guard let task = task else { return }
                
                DispatchQueue.main.async {
                    task.progress.accept(Float(progress.fractionCompleted))
                    task.downloadedSize.accept(progress.completedUnitCount)
                    task.totalSize.accept(progress.totalUnitCount)
                    
                    // 计算下载速度
                    if let startTime = task.startTime {
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        if elapsedTime > 0 {
                            let speed = Double(progress.completedUnitCount) / elapsedTime
                            task.speed.accept(self.formatSpeed(speed))
                        }
                    }
                }
            }
            .response { [weak self, weak task] response in
                guard let self = self, let task = task else { return }
                
                DispatchQueue.main.async {
                    switch response.result {
                    case .success:
                        task.status.accept(.completed)
                        task.progress.accept(1.0)
                        self.saveDownloadInfo(task: task)
                        completion(.success(()))
                        
                    case .failure(let error):
                        task.status.accept(.failed)
                        task.error.accept(error)
                        completion(.failure(error))
                    }
                    
                    // 检查队列中是否有等待的下载
                    self.startNextWaitingDownload()
                }
            }
        
        task.downloadRequest = downloadRequest
    }
    
    // MARK: - 暂停下载
    func pauseDownload(taskId: String) {
        guard let task = findTask(by: taskId),
              task.status.value == .downloading else { return }
        
        task.downloadRequest?.suspend()
        task.status.accept(.paused)
    }
    
    // MARK: - 恢复下载
    func resumeDownload(taskId: String) {
        guard let task = findTask(by: taskId),
              task.status.value == .paused else { return }
        
        task.downloadRequest?.resume()
        task.status.accept(.downloading)
    }
    
    // MARK: - 取消下载
    func cancelDownload(taskId: String) {
        guard let task = findTask(by: taskId) else { return }
        
        task.downloadRequest?.cancel()
        task.status.accept(.cancelled)
        
        // 删除未完成的文件
        if task.status.value != .completed {
            try? fileManager.removeItem(at: task.destinationURL)
        }
        
        startNextWaitingDownload()
    }
    
    // MARK: - 删除下载
    func deleteDownload(taskId: String) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let task = self.findTask(by: taskId) else {
                observer.onError(DownloadError.taskNotFound)
                return Disposables.create()
            }
            
            // 如果正在下载，先取消
            if task.status.value == .downloading {
                self.cancelDownload(taskId: taskId)
            }
            
            // 删除文件
            do {
                if self.fileManager.fileExists(atPath: task.destinationURL.path) {
                    try self.fileManager.removeItem(at: task.destinationURL)
                }
                
                // 从任务列表中移除
                self.removeTaskFromList(taskId: taskId)
                
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            
            return Disposables.create()
        }
    }
    
    // MARK: - 检查文件是否已下载
    func isDownloaded(song: Song) -> Bool {
        guard let task = findTask(by: song.sid) else { return false }
        return task.status.value == .completed && fileManager.fileExists(atPath: task.destinationURL.path)
    }
    
    // MARK: - 获取本地文件URL
    func getLocalURL(for song: Song) -> URL? {
        guard let task = findTask(by: song.sid),
              task.status.value == .completed,
              fileManager.fileExists(atPath: task.destinationURL.path) else {
            return nil
        }
        return task.destinationURL
    }
    
    // MARK: - 私有辅助方法
    
    private func findTask(by id: String) -> DownloadTask? {
        return downloadTasks.value.first { $0.id == id }
    }
    
    private func addTaskToList(_ task: DownloadTask) {
        var currentTasks = downloadTasks.value
        currentTasks.append(task)
        downloadTasks.accept(currentTasks)
    }
    
    private func removeTaskFromList(taskId: String) {
        var currentTasks = downloadTasks.value
        currentTasks.removeAll { $0.id == taskId }
        downloadTasks.accept(currentTasks)
    }
    
    private func startNextWaitingDownload() {
        let waitingTasks = downloadTasks.value.filter { $0.status.value == .waiting }
        
        if activeDownloads.value < maxConcurrentDownloads, let nextTask = waitingTasks.first {
            performDownload(task: nextTask) { _ in }
        }
    }
    
    private func generateFilename(for song: Song) -> String {
        let safeName = song.name.replacingOccurrences(of: "/", with: "_")
        let safeArtist = song.artist.replacingOccurrences(of: "/", with: "_")
        return "\(safeArtist) - \(safeName).mp3"
    }
    
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        }
    }
    
    private func parseSongFromFilename(_ filename: String) -> Song? {
        // 简单的文件名解析，实际项目中可能需要更复杂的逻辑
        let nameWithoutExtension = filename.replacingOccurrences(of: ".mp3", with: "")
        let components = nameWithoutExtension.components(separatedBy: " - ")
        
        if components.count >= 2 {
            let artist = components[0]
            let title = components[1]
            
            return Song(
                sid: nameWithoutExtension.hashValue.description,
                name: title,
                url: "",
                pic_url: "",
                lrc_url: "",
                artist: artist,
                album: "",
                format: "mp3",
                time: 0
            )
        }
        
        return nil
    }
    
    private func saveDownloadInfo(task: DownloadTask) {
        // 保存下载信息到UserDefaults或数据库
        // 这里可以根据需要实现持久化存储
    }
}

// MARK: - 下载错误类型
enum DownloadError: Error, LocalizedError {
    case invalidURL
    case alreadyExists
    case taskNotFound
    case diskSpaceInsufficient
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "下载链接无效"
        case .alreadyExists:
            return "文件已存在"
        case .taskNotFound:
            return "下载任务不存在"
        case .diskSpaceInsufficient:
            return "磁盘空间不足"
        case .networkError:
            return "网络连接错误"
        }
    }
}

// MARK: - 下载管理器扩展 - 批量操作
extension DownloadManager {
    
    /// 批量下载歌曲
    func batchDownload(songs: [Song]) -> Observable<Void> {
        let downloadObservables = songs.map { startDownload(song: $0) }
        return Observable.merge(downloadObservables)
    }
    
    /// 暂停所有下载
    func pauseAllDownloads() {
        let activeTasks = downloadTasks.value.filter { $0.status.value == .downloading }
        activeTasks.forEach { pauseDownload(taskId: $0.id) }
    }
    
    /// 恢复所有暂停的下载
    func resumeAllDownloads() {
        let pausedTasks = downloadTasks.value.filter { $0.status.value == .paused }
        pausedTasks.forEach { resumeDownload(taskId: $0.id) }
    }
    
    /// 清理失败的下载
    func cleanupFailedDownloads() {
        let failedTasks = downloadTasks.value.filter { $0.status.value == .failed }
        failedTasks.forEach { 
            try? fileManager.removeItem(at: $0.destinationURL)
            removeTaskFromList(taskId: $0.id)
        }
    }
    
    /// 获取下载统计信息
    var downloadStatistics: Observable<DownloadStatistics> {
        return downloadTasks.map { tasks in
            DownloadStatistics(
                total: tasks.count,
                completed: tasks.filter { $0.status.value == .completed }.count,
                downloading: tasks.filter { $0.status.value == .downloading }.count,
                failed: tasks.filter { $0.status.value == .failed }.count,
                waiting: tasks.filter { $0.status.value == .waiting }.count
            )
        }
    }
}

// MARK: - 下载统计信息
struct DownloadStatistics {
    let total: Int
    let completed: Int
    let downloading: Int
    let failed: Int
    let waiting: Int
} 