#if canImport(UIKit)
import AVFoundation
import Foundation
import MediaPlayer
import RxRelay
import UIKit

enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error
}

final class AudioManager: NSObject {
    static let shared = AudioManager()

    let playbackState = BehaviorRelay<PlaybackState>(value: .idle)
    let currentTime = BehaviorRelay<TimeInterval>(value: 0)
    let duration = BehaviorRelay<TimeInterval>(value: 0)
    let progress = BehaviorRelay<Float>(value: 0)
    let playbackError = PublishRelay<String>()

    var isPlaying: Bool {
        playbackState.value == .playing && player?.rate != 0
    }

    private var player: AVPlayer?
    private var currentSong: Song?
    private var periodicTimeObserver: Any?
    private var playbackEndObserver: NSObjectProtocol?
    private var playbackFailureObserver: NSObjectProtocol?
    private var playbackStalledObserver: NSObjectProtocol?
    private var itemStatusObservation: NSKeyValueObservation?
    private var timeControlStatusObservation: NSKeyValueObservation?
    private var artworkTask: Task<Void, Never>?
    private var intendsToPlay = false

    private override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        observeAudioSession()
    }

    func play(from url: URL, song: Song) {
        stop(resetNowPlayingInfo: false)
        currentSong = song
        guard url.isFileURL || url.scheme?.lowercased() == "https" else {
            reportPlaybackFailure(L10n.insecureConnectionBlocked)
            return
        }

        intendsToPlay = true
        playbackState.accept(.loading)
        duration.accept(TimeInterval(song.time))

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        installPeriodicTimeObserver(on: player)
        observePlaybackNotifications(for: item)
        observePlaybackState(player: player, item: item)

        player.play()
        updateNowPlayingInfo()
        loadArtworkIfNeeded(for: song)
    }

    func pause() {
        guard let player else { return }
        intendsToPlay = false
        player.pause()
        playbackState.accept(.paused)
        updateNowPlayingInfo()
    }

    func resume() {
        guard let player else {
            reportPlaybackFailure(L10n.playbackUnavailable)
            return
        }
        intendsToPlay = true
        playbackState.accept(.loading)
        player.play()
        updateNowPlayingInfo()
    }

    func reportPlaybackFailure(_ message: String) {
        intendsToPlay = false
        player?.pause()
        playbackState.accept(.error)
        playbackError.accept(message)
        updateNowPlayingInfo()
    }

    func stop() {
        stop(resetNowPlayingInfo: true)
    }

    func seek(to time: TimeInterval) {
        guard time.isFinite else { return }
        player?.seek(to: CMTime(seconds: max(0, time), preferredTimescale: 600))
        updatePlaybackTime(time)
        updateNowPlayingInfo()
    }

    func playNext() {
        NotificationCenter.default.post(name: .audioManagerPlayNext, object: nil)
    }

    func playPrevious() {
        NotificationCenter.default.post(name: .audioManagerPlayPrevious, object: nil)
    }

    private func stop(resetNowPlayingInfo: Bool) {
        artworkTask?.cancel()
        artworkTask = nil
        intendsToPlay = false
        removePlayerObservers()
        player?.pause()
        player = nil
        currentTime.accept(0)
        duration.accept(0)
        progress.accept(0)
        playbackState.accept(.stopped)

        if resetNowPlayingInfo {
            currentSong = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    private func installPeriodicTimeObserver(on player: AVPlayer) {
        periodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.25, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.updatePlaybackTime(time.seconds)
            }
        }
    }

    private func observePlaybackNotifications(for item: AVPlayerItem) {
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.playNext()
            }
        }

        playbackFailureObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            if let error {
                print("Playback failed: \(error.localizedDescription)")
            }
            Task { @MainActor in
                self?.reportPlaybackFailure(L10n.playbackFailed)
            }
        }

        playbackStalledObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.intendsToPlay else { return }
                self.playbackState.accept(.loading)
                self.player?.play()
            }
        }
    }

    private func observePlaybackState(player: AVPlayer, item: AVPlayerItem) {
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            let statusRawValue = item.status.rawValue
            let errorDescription = item.error?.localizedDescription
            Task { @MainActor in
                self?.handleItemStatus(statusRawValue, errorDescription: errorDescription)
            }
        }

        timeControlStatusObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { [weak self] player, _ in
            let statusRawValue = player.timeControlStatus.rawValue
            Task { @MainActor in
                self?.handleTimeControlStatus(statusRawValue)
            }
        }
    }

    private func handleItemStatus(_ statusRawValue: Int, errorDescription: String?) {
        switch statusRawValue {
        case AVPlayerItem.Status.unknown.rawValue:
            if intendsToPlay {
                playbackState.accept(.loading)
            }
        case AVPlayerItem.Status.readyToPlay.rawValue:
            if intendsToPlay {
                player?.play()
            }
        case AVPlayerItem.Status.failed.rawValue:
            if let errorDescription {
                print("Player item failed: \(errorDescription)")
            }
            reportPlaybackFailure(L10n.playbackFailed)
        default:
            reportPlaybackFailure(L10n.playbackFailed)
        }
    }

    private func handleTimeControlStatus(_ statusRawValue: Int) {
        guard playbackState.value != .error else { return }

        switch statusRawValue {
        case AVPlayer.TimeControlStatus.paused.rawValue:
            playbackState.accept(intendsToPlay ? .loading : .paused)
        case AVPlayer.TimeControlStatus.waitingToPlayAtSpecifiedRate.rawValue:
            playbackState.accept(.loading)
        case AVPlayer.TimeControlStatus.playing.rawValue:
            playbackState.accept(.playing)
        default:
            playbackState.accept(.loading)
        }
        updateNowPlayingInfo()
    }

    private func removePlayerObservers() {
        if let periodicTimeObserver, let player {
            player.removeTimeObserver(periodicTimeObserver)
        }
        periodicTimeObserver = nil

        if let playbackEndObserver {
            NotificationCenter.default.removeObserver(playbackEndObserver)
        }
        playbackEndObserver = nil

        if let playbackFailureObserver {
            NotificationCenter.default.removeObserver(playbackFailureObserver)
        }
        playbackFailureObserver = nil

        if let playbackStalledObserver {
            NotificationCenter.default.removeObserver(playbackStalledObserver)
        }
        playbackStalledObserver = nil

        itemStatusObservation?.invalidate()
        itemStatusObservation = nil
        timeControlStatusObservation?.invalidate()
        timeControlStatusObservation = nil
    }

    private func updatePlaybackTime(_ time: TimeInterval) {
        guard time.isFinite else { return }
        currentTime.accept(time)

        if let itemDuration = player?.currentItem?.duration.seconds,
           itemDuration.isFinite,
           itemDuration > 0 {
            duration.accept(itemDuration)
        }

        let total = duration.value
        progress.accept(total > 0 ? Float(min(max(time / total, 0), 1)) : 0)
    }

    private func updateNowPlayingInfo(artwork: MPMediaItemArtwork? = nil) {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.name,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPMediaItemPropertyPlaybackDuration: duration.value,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime.value,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
        ]
        if let artwork {
            info[MPMediaItemPropertyArtwork] = artwork
        } else if let existingArtwork = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] {
            info[MPMediaItemPropertyArtwork] = existingArtwork
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func loadArtworkIfNeeded(for song: Song) {
        guard let url = NetworkManager.shared.secureContentURL(from: song.pic_url) else { return }

        artworkTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                try Task.checkCancellation()
                guard let image = UIImage(data: data) else { return }
                let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                self?.updateNowPlayingInfo(artwork: artwork)
            } catch is CancellationError {
                return
            } catch {
                print("Artwork loading failed: \(error.localizedDescription)")
            }
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetoothA2DP, .allowBluetoothHFP]
            )
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error.localizedDescription)")
        }
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playNext() }
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.playPrevious() }
            return .success
        }
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in self?.seek(to: event.positionTime) }
            return .success
        }
    }

    private func observeAudioSession() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterrupted),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioRouteChanged),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func audioSessionInterrupted(_ notification: Notification) {
        guard let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            pause()
        case .ended:
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            if AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume) {
                resume()
            }
        @unknown default:
            break
        }
    }

    @objc private func audioRouteChanged(_ notification: Notification) {
        guard let rawReason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              AVAudioSession.RouteChangeReason(rawValue: rawReason) == .oldDeviceUnavailable else { return }
        pause()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

#endif
