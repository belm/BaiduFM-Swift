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
