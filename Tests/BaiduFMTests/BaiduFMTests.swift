@testable import BaiduFM
import Foundation

#if canImport(Testing)
import Testing

@Suite("Baidu FM core behavior")
struct BaiduFMTests {
    @Test("Formats playback durations")
    func formatsPlaybackDuration() {
        #expect(Common.getMinuteDisplay(seconds: 0) == "00:00")
        #expect(Common.getMinuteDisplay(seconds: 125) == "02:05")
    }

    @Test("Parses timestamped LRC lines")
    func parsesLyrics() {
        let lyrics = Common.praseSongLrc(lrc: "[00:01.00]First line\n[00:05.25]Second line")

        #expect(lyrics.count == 2)
        #expect(lyrics[0].lrc == "First line")
        #expect(lyrics[0].time == 1)
        #expect(lyrics[1].lrc == "Second line")
        #expect(lyrics[1].time == 5)
    }

    @Test("Builds a modern song model")
    func buildsSong() {
        let song = makeSong()
        #expect(song.sid == "42")
        #expect(song.name == "Example")
        #expect(song.time == 180)
    }

    @Test("Rejects insecure API endpoints")
    func rejectsInsecureAPIEndpoint() {
        #expect(apiConfigurationRejectsInsecureEndpoint())
    }

    @Test("Builds encoded HTTPS API requests")
    func buildsSecureAPIRequest() throws {
        let queryItems = try secureAPIQueryItems()
        #expect(queryItems["tn"] == "playlist")
        #expect(queryItems["id"] == "rock & roll")
    }

    @Test("Builds stable and safe download file names")
    func buildsSafeDownloadFileNames() {
        #expect(DownloadPathPolicy.fileName(songID: "track-42", format: "MP3") == "track-42.mp3")

        let unsafeName = DownloadPathPolicy.fileName(songID: " ../track/42 ", format: ".M4A")
        #expect(!unsafeName.contains("/"))
        #expect(!unsafeName.contains(".."))
        #expect(unsafeName.hasSuffix(".m4a"))
    }

    @Test("Persists and restores download state")
    func persistsDownloadManifest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BaiduFMTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = DownloadManifestStore(fileURL: directory.appendingPathComponent("manifest.json"))
        let record = makeDownloadRecord()
        try store.save(DownloadManifest(records: [record]))

        #expect(store.load().records == [record])
    }

    @Test("Recovers from a corrupt download manifest")
    func recoversFromCorruptDownloadManifest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BaiduFMTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let manifestURL = directory.appendingPathComponent("manifest.json")
        try Data("not-json".utf8).write(to: manifestURL)
        let store = DownloadManifestStore(fileURL: manifestURL)

        #expect(store.load().records.isEmpty)
        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(backups.contains { $0.contains("corrupt-") })
    }

    @Test("Retries only transient failures with a bounded backoff")
    func retriesTransientFailures() {
        #expect(ReliabilityRetryPolicy.shouldRetry(statusCode: 503, attempt: 0))
        #expect(ReliabilityRetryPolicy.shouldRetry(urlErrorCode: URLError.timedOut.rawValue, attempt: 2))
        #expect(!ReliabilityRetryPolicy.shouldRetry(statusCode: 404, attempt: 0))
        #expect(!ReliabilityRetryPolicy.shouldRetry(statusCode: 503, attempt: 3))
        #expect(ReliabilityRetryPolicy.delay(forAttempt: 0) == 0.5)
        #expect(ReliabilityRetryPolicy.delay(forAttempt: 10) == 4)
    }
}
#elseif canImport(XCTest)
import XCTest

final class BaiduFMTests: XCTestCase {
    func testFormatsPlaybackDuration() {
        XCTAssertEqual(Common.getMinuteDisplay(seconds: 0), "00:00")
        XCTAssertEqual(Common.getMinuteDisplay(seconds: 125), "02:05")
    }

    func testParsesTimestampedLyrics() {
        let lyrics = Common.praseSongLrc(lrc: "[00:01.00]First line\n[00:05.25]Second line")
        XCTAssertEqual(lyrics.count, 2)
        XCTAssertEqual(lyrics[0].lrc, "First line")
        XCTAssertEqual(lyrics[0].time, 1)
        XCTAssertEqual(lyrics[1].lrc, "Second line")
        XCTAssertEqual(lyrics[1].time, 5)
    }

    func testBuildsSong() {
        let song = makeSong()
        XCTAssertEqual(song.sid, "42")
        XCTAssertEqual(song.name, "Example")
        XCTAssertEqual(song.time, 180)
    }

    func testRejectsInsecureAPIEndpoint() {
        XCTAssertTrue(apiConfigurationRejectsInsecureEndpoint())
    }

    func testBuildsSecureAPIRequest() throws {
        let queryItems = try secureAPIQueryItems()
        XCTAssertEqual(queryItems["tn"], "playlist")
        XCTAssertEqual(queryItems["id"], "rock & roll")
    }

    func testBuildsSafeDownloadFileNames() {
        XCTAssertEqual(DownloadPathPolicy.fileName(songID: "track-42", format: "MP3"), "track-42.mp3")

        let unsafeName = DownloadPathPolicy.fileName(songID: " ../track/42 ", format: ".M4A")
        XCTAssertFalse(unsafeName.contains("/"))
        XCTAssertFalse(unsafeName.contains(".."))
        XCTAssertTrue(unsafeName.hasSuffix(".m4a"))
    }

    func testPersistsDownloadManifest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BaiduFMTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = DownloadManifestStore(fileURL: directory.appendingPathComponent("manifest.json"))
        let record = makeDownloadRecord()
        try store.save(DownloadManifest(records: [record]))

        XCTAssertEqual(store.load().records, [record])
    }

    func testRecoversFromCorruptDownloadManifest() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BaiduFMTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let manifestURL = directory.appendingPathComponent("manifest.json")
        try Data("not-json".utf8).write(to: manifestURL)
        let store = DownloadManifestStore(fileURL: manifestURL)

        XCTAssertTrue(store.load().records.isEmpty)
        let backups = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        XCTAssertTrue(backups.contains { $0.contains("corrupt-") })
    }

    func testRetriesTransientFailures() {
        XCTAssertTrue(ReliabilityRetryPolicy.shouldRetry(statusCode: 503, attempt: 0))
        XCTAssertTrue(ReliabilityRetryPolicy.shouldRetry(urlErrorCode: URLError.timedOut.rawValue, attempt: 2))
        XCTAssertFalse(ReliabilityRetryPolicy.shouldRetry(statusCode: 404, attempt: 0))
        XCTAssertFalse(ReliabilityRetryPolicy.shouldRetry(statusCode: 503, attempt: 3))
        XCTAssertEqual(ReliabilityRetryPolicy.delay(forAttempt: 0), 0.5)
        XCTAssertEqual(ReliabilityRetryPolicy.delay(forAttempt: 10), 4)
    }
}
#endif

private func makeSong() -> Song {
    Song(
        sid: "42",
        name: "Example",
        url: "https://example.com/song.mp3",
        pic_url: "https://example.com/artwork.jpg",
        lrc_url: "/lyrics/42.lrc",
        artist: "Artist",
        album: "Album",
        format: "mp3",
        time: 180
    )
}

private func makeDownloadRecord() -> DownloadRecord {
    DownloadRecord(
        song: DownloadSongSnapshot(song: makeSong()),
        status: .paused,
        fileName: "42.mp3",
        downloadedBytes: 1_024,
        expectedBytes: 2_048,
        taskIdentifier: 7,
        resumeData: Data([1, 2, 3]),
        retryCount: 1,
        lastError: nil,
        updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
    )
}

private func apiConfigurationRejectsInsecureEndpoint() -> Bool {
    do {
        _ = try APIConfiguration(baseURLString: "http://example.com")
        return false
    } catch let error as APIConfigurationError {
        return error == .insecureTransport
    } catch {
        return false
    }
}

private func secureAPIQueryItems() throws -> [String: String] {
    let configuration = try APIConfiguration(baseURLString: "https://example.com")
    let url = try configuration.endpoint(queryItems: [
        URLQueryItem(name: "tn", value: "playlist"),
        URLQueryItem(name: "id", value: "rock & roll"),
    ])
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        throw APIConfigurationError.invalidEndpoint
    }
    return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
        item.value.map { (item.name, $0) }
    })
}
