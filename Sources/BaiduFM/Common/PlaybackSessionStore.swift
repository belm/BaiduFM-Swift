import Foundation

nonisolated struct PlaybackSongSnapshot: Codable, Equatable, Sendable {
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

    @MainActor func makeSong() -> Song {
        Song(
            sid: sid,
            name: name,
            url: songURL,
            pic_url: pictureURL,
            lrc_url: lyricsURL,
            artist: artist,
            album: album,
            format: format,
            time: duration
        )
    }
}

nonisolated struct PlaybackSessionSnapshot: Codable, Equatable, Sendable {
    let song: PlaybackSongSnapshot
    let position: TimeInterval
    let savedAt: Date
}

nonisolated enum PlaybackRestorePolicy {
    static func safePosition(_ position: TimeInterval, duration: Int) -> TimeInterval {
        guard position.isFinite else { return 0 }
        let nonnegativePosition = max(position, 0)
        guard duration > 0 else { return nonnegativePosition }

        let totalDuration = TimeInterval(duration)
        let boundedPosition = min(nonnegativePosition, totalDuration)
        return boundedPosition >= max(totalDuration - 3, 0) ? 0 : boundedPosition
    }
}

@MainActor final class PlaybackSessionStore {
    static let shared = PlaybackSessionStore()

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "PLAYBACK_SESSION_V1") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> PlaybackSessionSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            let snapshot = try JSONDecoder().decode(PlaybackSessionSnapshot.self, from: data)
            guard snapshot.position.isFinite, snapshot.position >= 0 else {
                clear()
                return nil
            }
            return snapshot
        } catch {
            clear()
            return nil
        }
    }

    func save(song: Song, position: TimeInterval) {
        let snapshot = PlaybackSessionSnapshot(
            song: PlaybackSongSnapshot(song: song),
            position: max(position.isFinite ? position : 0, 0),
            savedAt: Date()
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}
