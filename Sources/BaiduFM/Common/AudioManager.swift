//
//  AudioManager.swift
//  BaiduFM
//
//  音频播放管理器 - 使用AVAudioPlayer替代已废弃的MPMoviePlayerController
//  支持后台播放、远程控制、播放进度控制等功能
//

import Foundation
import AVFoundation
import MediaPlayer
import RxSwift
import RxCocoa

// MARK: - 播放状态枚举
enum PlaybackState {
    case idle       // 空闲状态
    case loading    // 加载中
    case playing    // 播放中
    case paused     // 暂停
    case stopped    // 停止
    case error      // 错误
}

// MARK: - 音频管理器
class AudioManager: NSObject {
    
    // MARK: - 单例模式
    static let shared = AudioManager()
    
    // MARK: - 私有属性
    private var audioPlayer: AVAudioPlayer?
    private var currentSong: Song?
    private var playbackTimer: Timer?
    private let disposeBag = DisposeBag()
    
    // MARK: - 公共属性 - 使用RxSwift进行响应式编程
    let playbackState = BehaviorRelay<PlaybackState>(value: .idle)
    let currentTime = BehaviorRelay<TimeInterval>(value: 0.0)
    let duration = BehaviorRelay<TimeInterval>(value: 0.0)
    let progress = BehaviorRelay<Float>(value: 0.0)
    
    // MARK: - 初始化
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteControlEvents()
        setupNotifications()
    }
    
    // MARK: - 音频会话配置
    private func setupAudioSession() {
        do {
            // 配置音频会话支持后台播放
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 远程控制事件配置
    private func setupRemoteControlEvents() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 播放命令
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        // 暂停命令
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // 下一首命令
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        // 上一首命令
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        // 进度控制命令
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: positionEvent.positionTime)
                return .success
            }
            return .commandFailed
        }
    }
    
    // MARK: - 通知配置
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioSessionRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    // MARK: - 音频中断处理
    @objc private func audioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 中断开始 - 暂停播放
            pause()
        case .ended:
            // 中断结束 - 根据选项决定是否恢复播放
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    resume()
                }
            }
        @unknown default:
            break
        }
    }
    
    // MARK: - 音频路由变化处理
    @objc private func audioSessionRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // 设备断开连接（如耳机拔出）- 暂停播放
            pause()
        default:
            break
        }
    }
    
    // MARK: - 播放音频文件
    func play(from url: URL, song: Song) {
        currentSong = song
        playbackState.accept(.loading)
        
        // 异步加载音频数据
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let audioData = try Data(contentsOf: url)
                let player = try AVAudioPlayer(data: audioData)
                player.delegate = self
                player.enableRate = true
                
                DispatchQueue.main.async {
                    self?.audioPlayer = player
                    self?.duration.accept(player.duration)
                    self?.updateNowPlayingInfo()
                    
                    if player.play() {
                        self?.playbackState.accept(.playing)
                        self?.startPlaybackTimer()
                    } else {
                        self?.playbackState.accept(.error)
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self?.playbackState.accept(.error)
                    print("音频播放失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 播放控制方法
    func pause() {
        audioPlayer?.pause()
        playbackState.accept(.paused)
        stopPlaybackTimer()
        updateNowPlayingInfo()
    }
    
    func resume() {
        if audioPlayer?.play() == true {
            playbackState.accept(.playing)
            startPlaybackTimer()
            updateNowPlayingInfo()
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackState.accept(.stopped)
        stopPlaybackTimer()
        currentTime.accept(0.0)
        progress.accept(0.0)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime.accept(time)
        updateProgress()
        updateNowPlayingInfo()
    }
    
    // MARK: - 播放列表控制（需要与DataCenter配合）
    func playNext() {
        // 通知DataCenter播放下一首
        NotificationCenter.default.post(name: NSNotification.Name("AudioManagerPlayNext"), object: nil)
    }
    
    func playPrevious() {
        // 通知DataCenter播放上一首  
        NotificationCenter.default.post(name: NSNotification.Name("AudioManagerPlayPrevious"), object: nil)
    }
    
    // MARK: - 播放计时器
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    private func updatePlaybackTime() {
        guard let player = audioPlayer else { return }
        let time = player.currentTime
        currentTime.accept(time)
        updateProgress()
        updateNowPlayingInfo()
    }
    
    private func updateProgress() {
        let current = currentTime.value
        let total = duration.value
        progress.accept(total > 0 ? Float(current / total) : 0.0)
    }
    
    // MARK: - 锁屏信息更新
    private func updateNowPlayingInfo() {
        guard let song = currentSong,
              let player = audioPlayer else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.name,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyAlbumTitle: song.album,
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: playbackState.value == .playing ? 1.0 : 0.0
        ]
        
        // 异步加载专辑封面
        if let imageURL = URL(string: song.pic_url) {
            DispatchQueue.global(qos: .background).async {
                if let imageData = try? Data(contentsOf: imageURL),
                   let image = UIImage(data: imageData) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    DispatchQueue.main.async {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - 清理资源
    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            // 播放完成，自动播放下一首
            playNext()
        } else {
            playbackState.accept(.error)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playbackState.accept(.error)
        if let error = error {
            print("音频解码错误: \(error.localizedDescription)")
        }
    }
} 