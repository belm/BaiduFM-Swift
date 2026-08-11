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
    static let play = value("action.play", defaultValue: "Play")
    static let pause = value("action.pause", defaultValue: "Pause")
    static let previousTrack = value("action.previous_track", defaultValue: "Previous track")
    static let nextTrack = value("action.next_track", defaultValue: "Next track")
    static let download = value("action.download", defaultValue: "Download")
    static let like = value("action.like", defaultValue: "Like")
    static let liked = value("action.liked", defaultValue: "Liked")
    static let resume = value("action.resume", defaultValue: "Resume")
    static let downloaded = value("action.downloaded", defaultValue: "Downloaded")

    static let chooseChannelHint = value(
        "accessibility.choose_channel_hint",
        defaultValue: "Opens the channel picker."
    )
    static let playPauseHint = value(
        "accessibility.play_pause_hint",
        defaultValue: "Starts or pauses the current track."
    )
    static let playbackPosition = value(
        "accessibility.playback_position",
        defaultValue: "Playback position"
    )
    static let playbackPositionHint = value(
        "accessibility.playback_position_hint",
        defaultValue: "Adjust to seek through the current track."
    )
    static let lyrics = value("accessibility.lyrics", defaultValue: "Lyrics")
    static let selected = value("accessibility.selected", defaultValue: "Selected")
    static let notSelected = value("accessibility.not_selected", defaultValue: "Not selected")
    static let available = value("accessibility.available", defaultValue: "Available")
    static let downloadCompletedAnnouncement = value(
        "accessibility.download_completed",
        defaultValue: "Download completed."
    )

    static let error = value("alert.error", defaultValue: "Error")
    static let playbackErrorTitle = value("alert.playback_error", defaultValue: "Playback Error")
    static let downloadErrorTitle = value("alert.download_error", defaultValue: "Download Error")
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
    static let downloadWaiting = value("download.state.waiting", defaultValue: "Waiting")
    static let downloadInProgress = value("download.state.downloading", defaultValue: "Downloading")
    static let downloadPaused = value("download.state.paused", defaultValue: "Paused — tap to resume")
    static let downloadCompleted = value("download.state.completed", defaultValue: "Downloaded")
    static let downloadFailed = value("download.state.failed", defaultValue: "Failed — tap to retry")
    static let downloadCancelledState = value("download.state.cancelled", defaultValue: "Cancelled — tap to retry")
    static let downloadProgressFormat = value("download.state.progress", defaultValue: "%@ %ld%%")
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
    static let networkOffline = value("network.offline", defaultValue: "You appear to be offline. The request will retry when possible.")
    static let networkTimedOut = value("network.timed_out", defaultValue: "The request timed out. Please try again.")
    static let invalidAPIConfiguration = value(
        "network.invalid_configuration",
        defaultValue: "The content service is not configured correctly."
    )
    static let insecureConnectionBlocked = value(
        "network.insecure_transport",
        defaultValue: "An insecure content URL was blocked. Configure an HTTPS content provider."
    )

    static let applicationConfigurationFailed = value(
        "app.configuration_failed",
        defaultValue: "Baidu FM could not load its interface. Please reinstall the app or contact support."
    )
    static let playbackFailed = value(
        "playback.failed",
        defaultValue: "This track could not be played. Please try again."
    )
    static let playbackUnavailable = value(
        "playback.unavailable",
        defaultValue: "Choose a track before starting playback."
    )

    static let invalidDownloadURL = value("download.invalid_url", defaultValue: "The download URL is invalid.")
    static let downloadExists = value("download.already_exists", defaultValue: "This song is already downloaded.")
    static let downloadTaskMissing = value("download.task_missing", defaultValue: "The download task no longer exists.")
    static let diskSpaceInsufficient = value("download.disk_space", defaultValue: "There is not enough disk space.")
    static let downloadNetworkError = value("download.network_error", defaultValue: "The download failed because of a network error.")
    static let downloadCancelled = value("download.cancelled", defaultValue: "The download was cancelled.")
    static let downloadFileMissing = value("download.file_missing", defaultValue: "The downloaded file is missing. Download it again.")
    static let downloadStorageErrorFormat = value("download.storage_error", defaultValue: "The download could not be saved: %@")

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
