import Foundation

nonisolated enum DownloadStatus: String, Codable, Sendable {
    case waiting
    case downloading
    case paused
    case completed
    case failed
    case cancelled
}

nonisolated struct DownloadSongSnapshot: Codable, Equatable, Sendable {
    let sid: String
    let name: String
    let artist: String
    let album: String
    let songURL: String
    let pictureURL: String
    let lyricsURL: String
    let duration: Int
    let format: String

    @MainActor init(song: Song) {
        sid = song.sid
        name = song.name
        artist = song.artist
        album = song.album
        songURL = song.song_url
        pictureURL = song.pic_url
        lyricsURL = song.lrc_url
        duration = song.time
        format = song.format
    }

    @MainActor func makeSong(localPath: String = "") -> Song {
        Song(
            sid: sid,
            name: name,
            artist: artist,
            album: album,
            song_url: songURL,
            pic_url: pictureURL,
            lrc_url: lyricsURL,
            time: duration,
            is_dl: localPath.isEmpty ? 0 : 1,
            dl_file: localPath,
            is_like: 0,
            is_recent: 0,
            format: format
        )
    }
}

nonisolated struct DownloadRecord: Codable, Equatable, Sendable {
    var song: DownloadSongSnapshot
    var status: DownloadStatus
    var fileName: String
    var downloadedBytes: Int64
    var expectedBytes: Int64
    var taskIdentifier: Int?
    var resumeData: Data?
    var retryCount: Int
    var lastError: String?
    var updatedAt: Date

    var progress: Float {
        guard expectedBytes > 0 else { return status == .completed ? 1 : 0 }
        return Float(min(max(Double(downloadedBytes) / Double(expectedBytes), 0), 1))
    }
}

nonisolated struct DownloadManifest: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = currentVersion
    var records: [DownloadRecord] = []
}

nonisolated struct DownloadManifestStore {
    let fileURL: URL
    private let fileManager: FileManager

    init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    func load() -> DownloadManifest {
        guard fileManager.fileExists(atPath: fileURL.path) else { return DownloadManifest() }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .millisecondsSince1970
            let manifest = try decoder.decode(DownloadManifest.self, from: data)
            guard manifest.version == DownloadManifest.currentVersion else {
                return DownloadManifest()
            }
            return manifest
        } catch {
            preserveCorruptManifest()
            return DownloadManifest()
        }
    }

    func save(_ manifest: DownloadManifest) throws {
        let parentDirectory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(
            at: parentDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(manifest).write(to: fileURL, options: .atomic)
    }

    private func preserveCorruptManifest() {
        let backupURL = fileURL
            .deletingPathExtension()
            .appendingPathExtension("corrupt-\(UUID().uuidString).json")
        try? fileManager.moveItem(at: fileURL, to: backupURL)
    }
}

nonisolated enum DownloadPathPolicy {
    static func fileName(songID: String, format: String) -> String {
        let trimmedID = songID.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeID = sanitize(trimmedID, fallback: "song")
        let safeFormat = sanitizeFormat(format)
        return "\(safeID).\(safeFormat)"
    }

    private static func sanitize(_ value: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "_" }
        let normalized = String(scalars).prefix(80)
        let base = normalized.isEmpty ? fallback : String(normalized)

        if base == value, value.count <= 80 {
            return base
        }
        return "\(base)_\(stableHash(value))"
    }

    private static func sanitizeFormat(_ value: String) -> String {
        let trimmed = value
            .trimmingCharacters(in: CharacterSet(charactersIn: ". "))
            .lowercased()
        let allowed = CharacterSet.alphanumerics
        let filtered = String(trimmed.unicodeScalars.filter { allowed.contains($0) }.prefix(10))
        return filtered.isEmpty ? "mp3" : filtered
    }

    private static func stableHash(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }
}
