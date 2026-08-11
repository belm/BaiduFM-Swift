import Foundation
import RxRelay
import RxSwift

@MainActor final class SongDownloadTask {
    let id: String
    let song: Song
    let url: URL?
    let destinationURL: URL

    let status: BehaviorRelay<DownloadStatus>
    let progress: BehaviorRelay<Float>
    let downloadedSize: BehaviorRelay<Int64>
    let totalSize: BehaviorRelay<Int64>
    let speed = BehaviorRelay<String>(value: "0 KB/s")
    let error = BehaviorRelay<Error?>(value: nil)

    var startedAt: Date?

    init(record: DownloadRecord, destinationURL: URL) {
        id = record.song.sid
        song = record.song.makeSong(localPath: record.status == .completed ? destinationURL.path : "")
        url = URL(string: record.song.songURL)
        self.destinationURL = destinationURL
        status = BehaviorRelay(value: record.status)
        progress = BehaviorRelay(value: record.progress)
        downloadedSize = BehaviorRelay(value: record.downloadedBytes)
        totalSize = BehaviorRelay(value: record.expectedBytes)
    }
}

nonisolated enum DownloadError: Error, LocalizedError {
    case invalidURL
    case alreadyExists
    case taskNotFound
    case diskSpaceInsufficient
    case networkError
    case cancelled
    case storageFailure(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.invalidDownloadURL
        case .alreadyExists:
            return L10n.downloadExists
        case .taskNotFound:
            return L10n.downloadTaskMissing
        case .diskSpaceInsufficient:
            return L10n.diskSpaceInsufficient
        case .networkError:
            return L10n.downloadNetworkError
        case .cancelled:
            return L10n.downloadCancelled
        case .storageFailure(let message):
            return String(format: L10n.downloadStorageErrorFormat, message)
        }
    }
}

nonisolated struct DownloadStatistics: Sendable {
    let total: Int
    let completed: Int
    let downloading: Int
    let failed: Int
    let waiting: Int
}

/// Owns one durable background download state machine for the entire application.
@MainActor final class DownloadManager: NSObject, URLSessionDownloadDelegate, URLSessionDelegate, @unchecked Sendable {
    static let shared = DownloadManager()
    // Keep the legacy identifier so an app update can reconnect to transfers already owned by iOS.
    nonisolated static let backgroundSessionIdentifier = "com.baidufm.download"

    let downloadTasks = BehaviorRelay<[SongDownloadTask]>(value: [])
    let activeDownloads = BehaviorRelay<Int>(value: 0)
    let totalDownloadsCount = BehaviorRelay<Int>(value: 0)
    let completedDownloadsCount = BehaviorRelay<Int>(value: 0)

    nonisolated let downloadsDirectory: URL

    private let maxConcurrentDownloads = 3
    private let fileManager: FileManager
    private let manifestStore: DownloadManifestStore
    private var records: [String: DownloadRecord] = [:]
    private var systemTasks: [String: URLSessionDownloadTask] = [:]
    private var observers: [String: [UUID: RxObserverBox<Void>]] = [:]
    private var retryJobs: [String: Task<Void, Never>] = [:]
    private var backgroundCompletionHandler: (() -> Void)?

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.background(
            withIdentifier: Self.backgroundSessionIdentifier
        )
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60 * 60 * 6
        configuration.waitsForConnectivity = true
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = maxConcurrentDownloads
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        let fileManager = FileManager.default
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
        let rootDirectory = applicationSupport.appendingPathComponent("BaiduFM", isDirectory: true)
        let downloadsDirectory = rootDirectory.appendingPathComponent("Downloads", isDirectory: true)

        self.fileManager = fileManager
        self.downloadsDirectory = downloadsDirectory
        manifestStore = DownloadManifestStore(
            fileURL: rootDirectory.appendingPathComponent("download-manifest.json")
        )
        super.init()

        prepareStorage()
        restoreManifest()
        restoreSystemTasks()
    }

    /// Enqueues a download. Disposing the Rx subscription only detaches its observer;
    /// it never cancels the durable background transfer.
    func startDownload(song: Song) -> Observable<Void> {
        Observable.create { [weak self] observer in
            let observerID = UUID()
            let observerBox = RxObserverBox(observer)

            Task { @MainActor [weak self] in
                self?.enqueue(song: song, observerID: observerID, observer: observerBox)
            }

            return Disposables.create {
                Task { @MainActor [weak self] in
                    self?.removeObserver(observerID, songID: song.sid)
                }
            }
        }
    }

    func pauseDownload(taskId: String) {
        guard var record = records[taskId], record.status == .downloading else { return }

        record.status = .paused
        record.updatedAt = Date()
        records[taskId] = record
        updateTaskView(for: record)
        persistManifest()

        let task = systemTasks.removeValue(forKey: taskId)
        task?.cancel { [weak self] resumeData in
            Task { @MainActor [weak self] in
                guard let self, var pausedRecord = self.records[taskId], pausedRecord.status == .paused else {
                    return
                }
                pausedRecord.resumeData = resumeData
                pausedRecord.taskIdentifier = nil
                pausedRecord.updatedAt = Date()
                self.records[taskId] = pausedRecord
                self.persistManifest()
            }
        }
        beginWaitingDownloads()
    }

    func resumeDownload(taskId: String) {
        guard var record = records[taskId], [.paused, .failed, .cancelled].contains(record.status) else {
            return
        }
        record.status = .waiting
        record.lastError = nil
        record.retryCount = 0
        record.updatedAt = Date()
        records[taskId] = record
        updateTaskView(for: record)
        persistManifest()
        beginWaitingDownloads()
    }

    func cancelDownload(taskId: String) {
        guard var record = records[taskId], record.status != .completed else { return }

        retryJobs.removeValue(forKey: taskId)?.cancel()
        systemTasks.removeValue(forKey: taskId)?.cancel()
        record.status = .cancelled
        record.resumeData = nil
        record.taskIdentifier = nil
        record.lastError = DownloadError.cancelled.localizedDescription
        record.updatedAt = Date()
        records[taskId] = record
        try? fileManager.removeItem(at: destinationURL(for: record))
        updateTaskView(for: record)
        persistManifest()
        finishObservers(for: taskId, result: .failure(DownloadError.cancelled))
        beginWaitingDownloads()
    }

    func deleteDownload(taskId: String) -> Observable<Void> {
        Observable.create { [weak self] observer in
            let observerBox = RxObserverBox(observer)
            Task { @MainActor [weak self] in
                guard let self else {
                    observerBox.onError(DownloadError.taskNotFound)
                    return
                }
                do {
                    try self.removeDownload(taskId: taskId)
                    observerBox.onCompleted()
                } catch {
                    observerBox.onError(error)
                }
            }
            return Disposables.create()
        }
    }

    func removeAllDownloads() throws {
        retryJobs.values.forEach { $0.cancel() }
        systemTasks.values.forEach { $0.cancel() }
        retryJobs.removeAll()
        systemTasks.removeAll()

        var removedIDs: [String] = []
        var firstError: Error?
        for (songID, record) in records {
            let fileURL = destinationURL(for: record)
            do {
                if fileManager.fileExists(atPath: fileURL.path) {
                    try fileManager.removeItem(at: fileURL)
                }
                removedIDs.append(songID)
            } catch {
                firstError = firstError ?? error
                var failedRecord = record
                failedRecord.status = .failed
                failedRecord.taskIdentifier = nil
                failedRecord.lastError = error.localizedDescription
                failedRecord.updatedAt = Date()
                records[songID] = failedRecord
                updateTaskView(for: failedRecord, error: error)
                finishObservers(for: songID, result: .failure(error))
            }
        }

        for songID in removedIDs {
            records.removeValue(forKey: songID)
            observers.removeValue(forKey: songID)?.values.forEach {
                $0.onError(DownloadError.cancelled)
            }
        }
        downloadTasks.accept(downloadTasks.value.filter { !removedIDs.contains($0.id) })
        publishCounts()
        persistManifest()
        synchronizeDatabaseForRemoved(songIDs: removedIDs)

        if let firstError {
            throw DownloadError.storageFailure(firstError.localizedDescription)
        }
    }

    func isDownloaded(song: Song) -> Bool {
        getLocalURL(for: song) != nil
    }

    func getLocalURL(for song: Song) -> URL? {
        guard let record = records[song.sid], record.status == .completed else {
            if !song.dl_file.isEmpty, fileManager.fileExists(atPath: song.dl_file) {
                return URL(fileURLWithPath: song.dl_file)
            }
            return nil
        }
        let url = destinationURL(for: record)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return url
    }

    func batchDownload(songs: [Song]) -> Observable<Void> {
        Observable.merge(songs.map(startDownload))
    }

    func pauseAllDownloads() {
        records.values
            .filter { $0.status == .downloading }
            .forEach { pauseDownload(taskId: $0.song.sid) }
    }

    func resumeAllDownloads() {
        records.values
            .filter { $0.status == .paused }
            .forEach { resumeDownload(taskId: $0.song.sid) }
    }

    func cleanupFailedDownloads() {
        let failedIDs = records.values
            .filter { $0.status == .failed || $0.status == .cancelled }
            .map(\.song.sid)
        failedIDs.forEach { try? removeDownload(taskId: $0) }
    }

    var downloadStatistics: Observable<DownloadStatistics> {
        downloadTasks.map { tasks in
            DownloadStatistics(
                total: tasks.count,
                completed: tasks.filter { $0.status.value == .completed }.count,
                downloading: tasks.filter { $0.status.value == .downloading }.count,
                failed: tasks.filter { $0.status.value == .failed }.count,
                waiting: tasks.filter { $0.status.value == .waiting }.count
            )
        }
    }

    func registerBackgroundCompletionHandler(
        identifier: String,
        completionHandler: @escaping () -> Void
    ) -> Bool {
        guard identifier == Self.backgroundSessionIdentifier else { return false }
        backgroundCompletionHandler = completionHandler
        _ = session
        return true
    }

    // MARK: URLSession delegates

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let fileName = downloadTask.taskDescription else { return }
        Task { @MainActor [weak self] in
            self?.handleProgress(
                fileName: fileName,
                downloadedBytes: totalBytesWritten,
                expectedBytes: totalBytesExpectedToWrite
            )
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let fileName = downloadTask.taskDescription else { return }

        if let response = downloadTask.response as? HTTPURLResponse,
           !(200..<300).contains(response.statusCode) {
            Task { @MainActor [weak self] in
                self?.handleHTTPFailure(fileName: fileName, statusCode: response.statusCode)
            }
            return
        }

        let destinationURL = downloadsDirectory.appendingPathComponent(fileName)
        do {
            let fileManager = FileManager.default
            try fileManager.createDirectory(
                at: downloadsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.moveItem(at: location, to: destinationURL)
            let attributes = try fileManager.attributesOfItem(atPath: destinationURL.path)
            let size = (attributes[.size] as? NSNumber)?.int64Value ?? 0
            guard size > 0 else {
                try? fileManager.removeItem(at: destinationURL)
                throw DownloadError.storageFailure("The downloaded file is empty.")
            }
            Task { @MainActor [weak self] in
                self?.handleCompletedFile(fileName: fileName, fileSize: size)
            }
        } catch {
            let message = error.localizedDescription
            Task { @MainActor [weak self] in
                self?.handleStorageFailure(fileName: fileName, message: message)
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error, let fileName = task.taskDescription else { return }
        let nsError = error as NSError
        let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data
        Task { @MainActor [weak self] in
            self?.handleTransferFailure(
                fileName: fileName,
                errorDomain: nsError.domain,
                errorCode: nsError.code,
                message: nsError.localizedDescription,
                resumeData: resumeData
            )
        }
    }

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor [weak self] in
            guard let self, let completionHandler = self.backgroundCompletionHandler else { return }
            self.backgroundCompletionHandler = nil
            completionHandler()
        }
    }

    // MARK: State machine

    private func enqueue(song: Song, observerID: UUID, observer: RxObserverBox<Void>) {
        if let existing = records[song.sid] {
            switch existing.status {
            case .completed:
                observer.onError(DownloadError.alreadyExists)
                return
            case .waiting, .downloading:
                observers[song.sid, default: [:]][observerID] = observer
                return
            case .paused, .failed, .cancelled:
                var resumed = existing
                resumed.song = DownloadSongSnapshot(song: song)
                resumed.status = .waiting
                resumed.lastError = nil
                resumed.retryCount = 0
                resumed.updatedAt = Date()
                records[song.sid] = resumed
                observers[song.sid, default: [:]][observerID] = observer
                updateTaskView(for: resumed)
                persistManifest()
                beginWaitingDownloads()
                return
            }
        }

        guard let url = URL(string: song.song_url), url.scheme?.lowercased() == "https" else {
            observer.onError(DownloadError.invalidURL)
            return
        }

        let availableCapacity = try? downloadsDirectory.resourceValues(
            forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        ).volumeAvailableCapacityForImportantUsage
        if let availableCapacity, availableCapacity < 20 * 1_024 * 1_024 {
            observer.onError(DownloadError.diskSpaceInsufficient)
            return
        }

        let snapshot = DownloadSongSnapshot(song: song)
        let record = DownloadRecord(
            song: snapshot,
            status: .waiting,
            fileName: DownloadPathPolicy.fileName(songID: song.sid, format: song.format),
            downloadedBytes: 0,
            expectedBytes: 0,
            taskIdentifier: nil,
            resumeData: nil,
            retryCount: 0,
            lastError: nil,
            updatedAt: Date()
        )
        records[song.sid] = record
        observers[song.sid, default: [:]][observerID] = observer
        appendTaskView(for: record)
        persistManifest()
        beginWaitingDownloads()
    }

    private func beginWaitingDownloads() {
        var availableSlots = maxConcurrentDownloads - systemTasks.count
        guard availableSlots > 0 else { return }

        let waitingRecords = records.values
            .filter { $0.status == .waiting }
            .sorted { $0.updatedAt < $1.updatedAt }

        for waitingRecord in waitingRecords where availableSlots > 0 {
            guard let url = URL(string: waitingRecord.song.songURL), url.scheme?.lowercased() == "https" else {
                markFailed(songID: waitingRecord.song.sid, error: DownloadError.invalidURL)
                continue
            }

            var record = waitingRecord
            let task: URLSessionDownloadTask
            if let resumeData = record.resumeData {
                task = session.downloadTask(withResumeData: resumeData)
            } else {
                task = session.downloadTask(with: url)
            }
            task.taskDescription = record.fileName
            task.priority = URLSessionTask.highPriority

            record.status = .downloading
            record.taskIdentifier = task.taskIdentifier
            record.resumeData = nil
            record.updatedAt = Date()
            records[record.song.sid] = record
            systemTasks[record.song.sid] = task
            updateTaskView(for: record, resetStartTime: true)
            task.resume()
            availableSlots -= 1
        }
        persistManifest()
    }

    private func handleProgress(fileName: String, downloadedBytes: Int64, expectedBytes: Int64) {
        guard let songID = songID(forFileName: fileName), var record = records[songID] else { return }
        guard record.status == .downloading else { return }

        let previousPercentage = Int(record.progress * 100)
        record.downloadedBytes = max(downloadedBytes, 0)
        record.expectedBytes = max(expectedBytes, 0)
        record.updatedAt = Date()
        records[songID] = record
        updateTaskView(for: record, publishList: Int(record.progress * 100) != previousPercentage)

        // Persist coarse progress checkpoints instead of writing on every callback.
        if record.downloadedBytes == record.expectedBytes || record.downloadedBytes % (2 * 1_024 * 1_024) < 128 * 1_024 {
            persistManifest()
        }
    }

    private func handleCompletedFile(fileName: String, fileSize: Int64) {
        guard let songID = songID(forFileName: fileName), var record = records[songID] else { return }

        retryJobs.removeValue(forKey: songID)?.cancel()
        systemTasks.removeValue(forKey: songID)
        record.status = .completed
        record.downloadedBytes = fileSize
        record.expectedBytes = fileSize
        record.taskIdentifier = nil
        record.resumeData = nil
        record.retryCount = 0
        record.lastError = nil
        record.updatedAt = Date()
        records[songID] = record
        updateTaskView(for: record)
        persistManifest()
        synchronizeDatabaseForCompleted(record)
        finishObservers(for: songID, result: .success(()))
        beginWaitingDownloads()
    }

    private func handleHTTPFailure(fileName: String, statusCode: Int) {
        guard let songID = songID(forFileName: fileName) else { return }
        systemTasks.removeValue(forKey: songID)
        let error = DownloadError.networkError

        if var record = records[songID],
           ReliabilityRetryPolicy.shouldRetry(statusCode: statusCode, attempt: record.retryCount) {
            record.retryCount += 1
            scheduleRetry(record: record)
        } else {
            markFailed(songID: songID, error: error)
        }
    }

    private func handleStorageFailure(fileName: String, message: String) {
        guard let songID = songID(forFileName: fileName) else { return }
        systemTasks.removeValue(forKey: songID)
        markFailed(songID: songID, error: DownloadError.storageFailure(message))
    }

    private func handleTransferFailure(
        fileName: String,
        errorDomain: String,
        errorCode: Int,
        message: String,
        resumeData: Data?
    ) {
        guard let songID = songID(forFileName: fileName), var record = records[songID] else { return }
        systemTasks.removeValue(forKey: songID)

        if record.status == .paused || record.status == .cancelled || record.status == .completed {
            if record.status == .paused, let resumeData {
                record.resumeData = resumeData
                record.taskIdentifier = nil
                record.updatedAt = Date()
                records[songID] = record
                persistManifest()
            }
            beginWaitingDownloads()
            return
        }

        let urlErrorCode = errorDomain == NSURLErrorDomain ? errorCode : nil
        if ReliabilityRetryPolicy.shouldRetry(urlErrorCode: urlErrorCode, attempt: record.retryCount) {
            record.retryCount += 1
            record.resumeData = resumeData
            scheduleRetry(record: record)
        } else {
            record.resumeData = resumeData
            records[songID] = record
            print("Download transfer failed for \(songID): \(message)")
            markFailed(songID: songID, error: DownloadError.networkError)
        }
    }

    private func scheduleRetry(record: DownloadRecord) {
        var queuedRecord = record
        queuedRecord.status = .waiting
        queuedRecord.taskIdentifier = nil
        queuedRecord.lastError = nil
        queuedRecord.updatedAt = Date()
        records[record.song.sid] = queuedRecord
        updateTaskView(for: queuedRecord)
        persistManifest()

        let delay = ReliabilityRetryPolicy.delay(forAttempt: max(queuedRecord.retryCount - 1, 0))
        retryJobs[record.song.sid]?.cancel()
        retryJobs[record.song.sid] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.retryJobs.removeValue(forKey: record.song.sid)
            self?.beginWaitingDownloads()
        }
    }

    private func markFailed(songID: String, error: Error) {
        guard var record = records[songID] else { return }
        retryJobs.removeValue(forKey: songID)?.cancel()
        systemTasks.removeValue(forKey: songID)
        record.status = .failed
        record.taskIdentifier = nil
        record.lastError = error.localizedDescription
        record.updatedAt = Date()
        records[songID] = record
        updateTaskView(for: record, error: error)
        persistManifest()
        finishObservers(for: songID, result: .failure(error))
        beginWaitingDownloads()
    }

    // MARK: Restoration and migration

    private func prepareStorage() {
        do {
            try fileManager.createDirectory(
                at: downloadsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var mutableDirectory = downloadsDirectory
            try? mutableDirectory.setResourceValues(resourceValues)
        } catch {
            print("Download storage setup failed: \(error.localizedDescription)")
        }
    }

    private func restoreManifest() {
        var restoredRecords = manifestStore.load().records
        var missingCompletedSongIDs: [String] = []

        #if canImport(UIKit)
        migrateLegacyDownloads(into: &restoredRecords)
        #endif

        for var record in restoredRecords {
            let destination = destinationURL(for: record)
            let fileSize = ((try? fileManager.attributesOfItem(atPath: destination.path)[.size]) as? NSNumber)?.int64Value ?? 0
            if fileSize > 0 {
                // A canonical file only appears after URLSession finishes moving its temporary file.
                // Promoting it here closes the crash window between the move and manifest/database updates.
                record.status = .completed
                record.downloadedBytes = fileSize
                record.expectedBytes = fileSize
                record.taskIdentifier = nil
                record.resumeData = nil
                record.retryCount = 0
                record.lastError = nil
            } else if record.status == .completed {
                record.status = .failed
                record.lastError = L10n.downloadFileMissing
                record.downloadedBytes = 0
                record.expectedBytes = 0
                missingCompletedSongIDs.append(record.song.sid)
            } else if record.status == .downloading {
                record.status = .waiting
                record.taskIdentifier = nil
            }
            records[record.song.sid] = record
        }

        let restoredTasks = records.values
            .sorted { $0.updatedAt < $1.updatedAt }
            .map { SongDownloadTask(record: $0, destinationURL: destinationURL(for: $0)) }
        downloadTasks.accept(restoredTasks)
        publishCounts()
        persistManifest()
        synchronizeDatabaseAfterRestoration(missingSongIDs: missingCompletedSongIDs)
    }

    private func restoreSystemTasks() {
        session.getAllTasks { [weak self] tasks in
            let downloads = tasks.compactMap { $0 as? URLSessionDownloadTask }
            Task { @MainActor [weak self] in
                self?.adoptSystemTasks(downloads)
            }
        }
    }

    private func adoptSystemTasks(_ tasks: [URLSessionDownloadTask]) {
        var adoptedFileNames = Set<String>()
        for task in tasks {
            guard let fileName = task.taskDescription,
                  let songID = songID(forFileName: fileName),
                  var record = records[songID] else {
                task.cancel()
                continue
            }
            adoptedFileNames.insert(fileName)
            record.status = task.state == .suspended ? .paused : .downloading
            record.taskIdentifier = task.taskIdentifier
            record.updatedAt = Date()
            records[songID] = record
            systemTasks[songID] = task
            updateTaskView(for: record, resetStartTime: true)
        }

        for (songID, var record) in records where record.status == .downloading && !adoptedFileNames.contains(record.fileName) {
            record.status = .waiting
            record.taskIdentifier = nil
            records[songID] = record
            updateTaskView(for: record)
        }
        persistManifest()
        beginWaitingDownloads()
    }

    #if canImport(UIKit)
    private func migrateLegacyDownloads(into restoredRecords: inout [DownloadRecord]) {
        let songList = SongList()
        let databaseSongs = songList.getAllDownload() ?? []
        guard !databaseSongs.isEmpty else { return }

        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        for song in databaseSongs {
            let fileName = DownloadPathPolicy.fileName(songID: song.sid, format: song.format)
            let destination = downloadsDirectory.appendingPathComponent(fileName)
            let oldManagerName = "\(song.artist.replacingOccurrences(of: "/", with: "_")) - \(song.name.replacingOccurrences(of: "/", with: "_")).mp3"
            let candidates = [
                song.dl_file.isEmpty ? nil : URL(fileURLWithPath: song.dl_file),
                documents?.appendingPathComponent("download").appendingPathComponent("\(song.sid).\(song.format)"),
                documents?.appendingPathComponent("Downloads").appendingPathComponent(oldManagerName),
            ].compactMap { $0 }

            if !fileManager.fileExists(atPath: destination.path),
               let source = candidates.first(where: { fileManager.fileExists(atPath: $0.path) }) {
                do {
                    try fileManager.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
                    try fileManager.moveItem(at: source, to: destination)
                } catch {
                    do {
                        try fileManager.copyItem(at: source, to: destination)
                    } catch {
                        print("Legacy download migration failed for \(song.sid): \(error.localizedDescription)")
                    }
                }
            }

            guard fileManager.fileExists(atPath: destination.path) else {
                _ = songList.markDownloadRemoved(sid: song.sid)
                continue
            }
            let fileSize = ((try? fileManager.attributesOfItem(atPath: destination.path)[.size]) as? NSNumber)?.int64Value ?? 0
            let snapshot = DownloadSongSnapshot(song: song)
            let record = DownloadRecord(
                song: snapshot,
                status: .completed,
                fileName: fileName,
                downloadedBytes: fileSize,
                expectedBytes: fileSize,
                taskIdentifier: nil,
                resumeData: nil,
                retryCount: 0,
                lastError: nil,
                updatedAt: Date()
            )
            restoredRecords.removeAll { $0.song.sid == song.sid }
            restoredRecords.append(record)
            _ = songList.markDownloaded(song: song, localPath: destination.path)
        }
    }
    #endif

    // MARK: Persistence and view synchronization

    private func persistManifest() {
        do {
            let manifest = DownloadManifest(
                records: records.values.sorted { $0.updatedAt < $1.updatedAt }
            )
            try manifestStore.save(manifest)
        } catch {
            print("Download state persistence failed: \(error.localizedDescription)")
        }
    }

    private func appendTaskView(for record: DownloadRecord) {
        var tasks = downloadTasks.value
        tasks.append(SongDownloadTask(record: record, destinationURL: destinationURL(for: record)))
        downloadTasks.accept(tasks)
        publishCounts()
    }

    private func updateTaskView(
        for record: DownloadRecord,
        error: Error? = nil,
        resetStartTime: Bool = false,
        publishList: Bool = true
    ) {
        guard let task = downloadTasks.value.first(where: { $0.id == record.song.sid }) else {
            appendTaskView(for: record)
            return
        }
        task.status.accept(record.status)
        task.progress.accept(record.progress)
        task.downloadedSize.accept(record.downloadedBytes)
        task.totalSize.accept(record.expectedBytes)
        task.error.accept(error)
        if resetStartTime {
            task.startedAt = Date()
        }
        if let startedAt = task.startedAt, record.status == .downloading {
            let elapsed = max(Date().timeIntervalSince(startedAt), 0.001)
            task.speed.accept(formatSpeed(Double(record.downloadedBytes) / elapsed))
        }
        if publishList {
            downloadTasks.accept(downloadTasks.value)
            publishCounts()
        }
    }

    private func publishCounts() {
        let tasks = downloadTasks.value
        activeDownloads.accept(tasks.filter { $0.status.value == .downloading }.count)
        totalDownloadsCount.accept(tasks.count)
        completedDownloadsCount.accept(tasks.filter { $0.status.value == .completed }.count)
    }

    private func removeDownload(taskId: String) throws {
        guard let record = records[taskId] else { throw DownloadError.taskNotFound }
        retryJobs.removeValue(forKey: taskId)?.cancel()
        systemTasks.removeValue(forKey: taskId)?.cancel()

        let fileURL = destinationURL(for: record)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
        records.removeValue(forKey: taskId)
        observers.removeValue(forKey: taskId)?.values.forEach {
            $0.onError(DownloadError.cancelled)
        }
        downloadTasks.accept(downloadTasks.value.filter { $0.id != taskId })
        publishCounts()
        persistManifest()
        synchronizeDatabaseForRemoved(songID: taskId)
        beginWaitingDownloads()
    }

    private func destinationURL(for record: DownloadRecord) -> URL {
        downloadsDirectory.appendingPathComponent(record.fileName)
    }

    private func songID(forFileName fileName: String) -> String? {
        records.values.first(where: { $0.fileName == fileName })?.song.sid
    }

    private func removeObserver(_ observerID: UUID, songID: String) {
        observers[songID]?.removeValue(forKey: observerID)
        if observers[songID]?.isEmpty == true {
            observers.removeValue(forKey: songID)
        }
    }

    private func finishObservers(for songID: String, result: Result<Void, Error>) {
        guard let pendingObservers = observers.removeValue(forKey: songID) else { return }
        for observer in pendingObservers.values {
            switch result {
            case .success:
                observer.onCompleted()
            case .failure(let error):
                observer.onError(error)
            }
        }
    }

    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1_024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
        if bytesPerSecond < 1_024 * 1_024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1_024)
        }
        return String(format: "%.1f MB/s", bytesPerSecond / (1_024 * 1_024))
    }

    private func synchronizeDatabaseForCompleted(_ record: DownloadRecord) {
        #if canImport(UIKit)
        let path = destinationURL(for: record).path
        let song = record.song.makeSong(localPath: path)
        guard SongList().markDownloaded(song: song, localPath: path) else { return }
        DataCenter.shared.loadDownloadedSongs()
        #endif
    }

    private func synchronizeDatabaseForRemoved(songID: String) {
        #if canImport(UIKit)
        guard SongList().markDownloadRemoved(sid: songID) else { return }
        DataCenter.shared.loadDownloadedSongs()
        #endif
    }

    private func synchronizeDatabaseForRemoved(songIDs: [String]) {
        #if canImport(UIKit)
        let songList = SongList()
        for songID in songIDs {
            _ = songList.markDownloadRemoved(sid: songID)
        }
        DataCenter.shared.loadDownloadedSongs()
        #endif
    }

    private func synchronizeDatabaseAfterRestoration(missingSongIDs: [String]) {
        #if canImport(UIKit)
        let songList = SongList()
        for record in records.values where record.status == .completed {
            let path = destinationURL(for: record).path
            _ = songList.markDownloaded(song: record.song.makeSong(localPath: path), localPath: path)
        }
        for songID in missingSongIDs {
            _ = songList.markDownloadRemoved(sid: songID)
        }
        DataCenter.shared.loadDownloadedSongs()
        #endif
    }
}
