import Foundation

nonisolated enum L10n {
    static let appName = value("app.name", defaultValue: "Baidu FM")
    static let channels = value("screen.channels", defaultValue: "Channels")
    static let songList = value("screen.song_list", defaultValue: "Songs")
    static let downloads = value("screen.downloads", defaultValue: "Downloads")
    static let likes = value("screen.likes", defaultValue: "My Likes")
    static let recents = value("screen.recents", defaultValue: "Recently Played")

    static let clearAll = value("action.clear_all", defaultValue: "Clear All")
    static let cancel = value("action.cancel", defaultValue: "Cancel")
    static let confirm = value("action.confirm", defaultValue: "Confirm")
    static let ok = value("action.ok", defaultValue: "OK")
    static let refresh = value("action.refresh", defaultValue: "Refresh")
    static let retry = value("action.retry", defaultValue: "Retry")

    static let error = value("alert.error", defaultValue: "Error")
    static let confirmClear = value("alert.confirm_clear", defaultValue: "Confirm Clear")
    static let clearDownloadsMessage = value(
        "alert.clear_downloads",
        defaultValue: "Are you sure you want to clear all downloaded songs? This action cannot be undone."
    )
    static let clearLikesMessage = value(
        "alert.clear_likes",
        defaultValue: "Are you sure you want to clear all liked songs? This action cannot be undone."
    )
    static let clearRecentsMessage = value(
        "alert.clear_recents",
        defaultValue: "Are you sure you want to clear all recently played songs? This action cannot be undone."
    )

    static let noDownloads = value("empty.downloads", defaultValue: "No downloaded songs yet.")
    static let noLikes = value(
        "empty.likes",
        defaultValue: "You haven't liked any songs yet.\nTap the heart icon on the player screen to add one."
    )
    static let noRecents = value(
        "empty.recents",
        defaultValue: "No recently played songs.\nStart listening to see your history here."
    )
    static let noData = value("empty.no_data", defaultValue: "No data")
    static let noSong = value("empty.no_song", defaultValue: "No song selected")
    static let noLyrics = value("empty.no_lyrics", defaultValue: "No lyrics")
    static let noLyricsDecorated = value("empty.no_lyrics_decorated", defaultValue: "♪ No lyrics ♪")
    static let loading = value("state.loading", defaultValue: "Loading…")
    static let unknownError = value("error.unknown", defaultValue: "Unknown error")

    static let chooseChannel = value("error.choose_channel", defaultValue: "Please select a channel first.")
    static let loadChannelsFailed = value(
        "error.load_channels",
        defaultValue: "Failed to load channels. Please check your network connection."
    )
    static let refreshChannelsFailed = value(
        "error.refresh_channels",
        defaultValue: "Failed to refresh channels."
    )
    static let loadSongsFailed = value(
        "error.load_songs",
        defaultValue: "Failed to load songs. Please check your network connection."
    )
    static let loadMoreSongsFailed = value(
        "error.load_more_songs",
        defaultValue: "Failed to load more songs."
    )

    static let invalidURL = value("network.invalid_url", defaultValue: "Invalid URL")
    static let noResponseData = value("network.no_data", defaultValue: "The server returned no data.")
    static let decodingFailed = value("network.decoding_failed", defaultValue: "Unable to read the server response.")
    static let serverErrorFormat = value("network.server_error", defaultValue: "Server error: %@")
    static let clientStatusFormat = value("network.client_status", defaultValue: "Client error: %ld")
    static let serverStatusFormat = value("network.server_status", defaultValue: "Server error: %ld")
    static let connectionFailed = value("network.connection_failed", defaultValue: "Network connection failed.")

    static let invalidDownloadURL = value("download.invalid_url", defaultValue: "The download URL is invalid.")
    static let downloadExists = value("download.already_exists", defaultValue: "This song is already downloaded.")
    static let downloadTaskMissing = value("download.task_missing", defaultValue: "The download task no longer exists.")
    static let diskSpaceInsufficient = value("download.disk_space", defaultValue: "There is not enough disk space.")
    static let downloadNetworkError = value("download.network_error", defaultValue: "The download failed because of a network error.")

    static let lyricsInvalid = value("lyrics.invalid", defaultValue: "Invalid lyrics format")
    static let lyricsLoadFailed = value("lyrics.load_failed", defaultValue: "Failed to load lyrics")
    static let lyricsQualityNone = value("lyrics.quality.none", defaultValue: "No lyrics")
    static let lyricsQualityPoor = value("lyrics.quality.poor", defaultValue: "Few lyric lines")
    static let lyricsQualityBasic = value("lyrics.quality.basic", defaultValue: "Basic lyrics")
    static let lyricsQualityGood = value("lyrics.quality.good", defaultValue: "Complete lyrics")

    private static func value(_ key: StaticString, defaultValue: String.LocalizationValue) -> String {
        String(localized: key, defaultValue: defaultValue, bundle: resourceBundle)
    }

    private static let resourceBundle: Bundle = {
        #if SWIFT_PACKAGE
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("BaiduFM_BaiduFM.bundle")
        return Bundle(url: bundleURL) ?? .main
        #else
        return .main
        #endif
    }()
}
