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

    var isPlaying: Bool {
        playbackState.value == .playing && player?.rate != 0
    }

    private var player: AVPlayer?
    private var currentSong: Song?
    private var periodicTimeObserver: Any?
    private var playbackEndObserver: NSObjectProtocol?
    private var artworkTask: Task<Void, Never>?

    private override init() {
        super.init()
        configureAudioSession()
        configureRemoteCommands()
        observeAudioSession()
    }

    func play(from url: URL, song: Song) {
        stop(resetNowPlayingInfo: false)
        playbackState.accept(.loading)
        currentSong = song
        duration.accept(TimeInterval(song.time))

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        self.player = player
        installPeriodicTimeObserver(on: player)
        observePlaybackEnd(for: item)

        player.play()
        playbackState.accept(.playing)
        updateNowPlayingInfo()
        loadArtworkIfNeeded(for: song)
    }

    func pause() {
        player?.pause()
        playbackState.accept(.paused)
        updateNowPlayingInfo()
    }

    func resume() {
        guard player != nil else { return }
        player?.play()
        playbackState.accept(.playing)
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

    private func observePlaybackEnd(for item: AVPlayerItem) {
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.playNext()
            }
        }
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
        guard let url = URL(string: song.pic_url) else { return }

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
