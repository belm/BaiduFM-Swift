import Foundation
import UIKit

// 播放器视图模型 - 管理音乐播放逻辑
class PlayerViewModel {
    
    // MARK: - Properties - 属性
    private let dataCenter = DataCenter.shared
    private let audioManager = AudioManager.shared
    private var parsedLyrics: [(lrc: String, time: Int)] = []
    
    // 当前歌曲信息
    var currentSong: Song? {
        return dataCenter.currentPlayingSong
    }
    
    var currentChannelName: String {
        return dataCenter.currentChannel?.name ?? "百度FM"
    }
    
    // MARK: - Initialization - 初始化
    func initialize() {
        loadInitialData()
    }
    
    // MARK: - Data Loading - 数据加载
    private func loadInitialData() {
        Task {
            do {
                // 加载歌曲列表
                try await dataCenter.loadSongListAsync()
                
                // 加载歌曲详情
                try await dataCenter.loadSongDetailsAsync()
                
                // 播放第一首歌
                DispatchQueue.main.async { [weak self] in
                    self?.dataCenter.playSong(at: 0)
                    self?.loadCurrentSongLyrics()
                }
            } catch {
                print("加载初始数据失败: \(error)")
            }
        }
    }
    
    private func loadCurrentSongLyrics() {
        guard let currentSong = currentSong,
              !currentSong.lrc_url.isEmpty else {
            parsedLyrics = []
            return
        }
        
        Task {
            do {
                let lrcString = try await HttpRequest.getLrcAsync(lrcUrl: currentSong.lrc_url)
                let lyrics = Common.praseSongLrc(lrc: lrcString)
                
                DispatchQueue.main.async { [weak self] in
                    self?.parsedLyrics = lyrics
                }
            } catch {
                print("加载歌词失败: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.parsedLyrics = []
                }
            }
        }
    }
    
    // MARK: - Player Control Methods - 播放控制方法
    func togglePlayPause() {
        if audioManager.isPlaying {
            audioManager.pause()
        } else {
            audioManager.resume()
        }
        
        // 发送播放状态变化通知
        NotificationCenter.default.post(name: .audioManagerPlaybackStateDidChange, object: nil)
    }
    
    func playNext() {
        dataCenter.playNext()
        loadCurrentSongLyrics()
        
        // 发送歌曲变化通知
        NotificationCenter.default.post(name: .audioManagerSongDidChange, object: nil)
    }
    
    func playPrevious() {
        dataCenter.playPrevious()
        loadCurrentSongLyrics()
        
        // 发送歌曲变化通知
        NotificationCenter.default.post(name: .audioManagerSongDidChange, object: nil)
    }
    
    func toggleLike() {
        guard let currentSong = currentSong else { return }
        
        // 这里添加收藏/取消收藏逻辑
        print("切换收藏状态: \(currentSong.title)")
        
        // 可以添加数据库操作来保存收藏状态
        // DatabaseManager.shared.toggleLikeSong(currentSong)
    }
    
    func downloadCurrentSong() {
        guard let currentSong = currentSong else { return }
        
        // 这里添加下载逻辑
        print("下载歌曲: \(currentSong.title)")
        
        // 可以使用DownloadManager来处理下载
        // DownloadManager.shared.downloadSong(currentSong)
    }
    
    // MARK: - Lyrics Methods - 歌词方法
    func getCurrentLyrics(currentTime: TimeInterval) -> String {
        let result = Common.currentLrcByTime(curLength: Int(currentTime), lrcArray: parsedLyrics)
        return result.0.isEmpty ? "暂无歌词" : result.0
    }
    
    func getNextLyricLine(currentTime: TimeInterval) -> String {
        let result = Common.currentLrcByTime(curLength: Int(currentTime), lrcArray: parsedLyrics)
        return result.1
    }
}

// MARK: - DataCenter Async Extensions - DataCenter异步扩展
extension DataCenter {
    func loadSongListAsync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // 这里需要根据实际的DataCenter实现来调整
            // 假设原来的loadSongList()方法返回一个Observable
            // 现在我们需要将其转换为async/await模式
            
            // 临时实现，您需要根据实际情况调整
            DispatchQueue.global().async {
                // 模拟异步加载
                Thread.sleep(forTimeInterval: 1.0)
                continuation.resume()
            }
        }
    }
    
    func loadSongDetailsAsync() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            // 这里需要根据实际的DataCenter实现来调整
            
            // 临时实现，您需要根据实际情况调整
            DispatchQueue.global().async {
                // 模拟异步加载
                Thread.sleep(forTimeInterval: 0.5)
                continuation.resume()
            }
        }
    }
}

// MARK: - AudioManager Extensions - AudioManager扩展
extension AudioManager {
    var isPlaying: Bool {
        // 这里需要根据AudioManager的实际实现来调整
        // 假设有一个playbackState属性或类似的状态检查
        return true // 临时实现
    }
    
    var currentProgress: Double {
        // 返回当前播放进度 (0.0 - 1.0)
        return currentTime / totalTime
    }
    
    var currentTime: TimeInterval {
        // 返回当前播放时间（秒）
        return 0.0 // 需要根据实际实现调整
    }
    
    var totalTime: TimeInterval {
        // 返回总时长（秒）
        return 0.0 // 需要根据实际实现调整
    }
} 