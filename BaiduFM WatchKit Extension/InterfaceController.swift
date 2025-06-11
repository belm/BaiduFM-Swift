//
//  InterfaceController.swift
//  BaiduFM WatchKit Extension
//
//  Created by lumeng on 15/4/26.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import WatchKit
import Foundation
import RxSwift
import RxCocoa

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var songImage: WKInterfaceImage!
    @IBOutlet weak var songNameLabel: WKInterfaceLabel!
    @IBOutlet weak var playButton: WKInterfaceButton!
    @IBOutlet weak var prevButton: WKInterfaceButton!
    @IBOutlet weak var nextButton: WKInterfaceButton!
    
    @IBOutlet weak var progressLabel: WKInterfaceLabel!
    @IBOutlet weak var songTimeLabel: WKInterfaceLabel!
    @IBOutlet weak var lrcLabel: WKInterfaceLabel!
    @IBOutlet weak var nextLrcLabel: WKInterfaceLabel!
    
    private let disposeBag = DisposeBag()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        // 绑定播放状态到UI
        AudioManager.shared.playbackState
            .asDriver(onErrorJustReturn: .idle)
            .drive(onNext: { [weak self] state in
                self?.updatePlayButton(for: state)
            })
            .disposed(by: disposeBag)
        
        // 绑定播放进度到UI
        AudioManager.shared.currentTime
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] time in
                self?.progressLabel.setText(Common.getMinuteDisplay(Int(time)))
                if let (curLrc, nextLrc) = self?.getCurrentLrc(for: time) {
                    self?.lrcLabel.setText(curLrc)
                    self?.nextLrcLabel.setText(nextLrc)
                }
            })
            .disposed(by: disposeBag)
            
        // 绑定歌曲总时长
        AudioManager.shared.duration
            .asDriver(onErrorJustReturn: 0)
            .drive(onNext: { [weak self] duration in
                self?.songTimeLabel.setText(Common.getMinuteDisplay(Int(duration)))
            })
            .disposed(by: disposeBag)
    }
    
    private func loadInitialData() {
        Task {
            if DataManager.shared.songInfoList.isEmpty {
                await DataManager.shared.getTop20SongInfoList()
            }
            // 确保在主线程上更新UI
            await MainActor.run {
                if let song = DataManager.shared.curSongInfo {
                    self.playSong(info: song)
                }
            }
        }
    }
    
    func playSong(info: SongInfo) {
        self.songNameLabel.setText("\(info.name) - \(info.artistName)")
        if let url = URL(string: info.songPicRadio) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.songImage.setImageData(data)
                    }
                }
            }
        }
        
        updateNavigationButtons()
        
        // 获取并播放歌曲
        Task {
            do {
                let songLink = try await HttpRequest.getSongLinkAsync(songid: info.id)
                DataManager.shared.curSongLink = songLink
                if let url = URL(string: songLink.songLink) {
                    let song = Song(sid: info.id, name: info.name, url: songLink.songLink, pic_url: info.songPicRadio, lrc_url: songLink.lrcLink, artist: info.artistName, album: info.albumName, format: songLink.format, time: songLink.time)
                    AudioManager.shared.play(from: url, song: song)
                }
                
                if let lrc = try await HttpRequest.getLrcAsync(lrcUrl: songLink.lrcLink) {
                    DataManager.shared.curLrcInfo = Common.praseSongLrc(lrc: lrc)
                }
                
            } catch {
                print("Failed to get song link or lrc: \(error)")
            }
        }
    }
    
    private func updatePlayButton(for state: PlaybackState) {
        switch state {
        case .playing:
            playButton.setBackgroundImage(UIImage(named: "btn_pause"))
        case .paused, .idle, .stopped, .error:
            playButton.setBackgroundImage(UIImage(named: "btn_play"))
        case .loading:
            // Optionally show a loading indicator
            break
        }
    }
    
    private func updateNavigationButtons() {
        prevButton.setEnabled(DataManager.shared.curIndex > 0)
        nextButton.setEnabled(DataManager.shared.curIndex < DataManager.shared.songInfoList.count - 1)
    }

    private func getCurrentLrc(for time: TimeInterval) -> (String, String) {
        return Common.currentLrcByTime(curLength: Int(time), lrcArray: DataManager.shared.curLrcInfo)
    }

    @IBAction func playButtonAction() {
        let state = AudioManager.shared.playbackState.value
        if state == .playing {
            AudioManager.shared.pause()
        } else {
            AudioManager.shared.resume()
        }
    }
    
    @IBAction func prevButtonAction() {
        DataManager.shared.curIndex -= 1
        if let song = DataManager.shared.curSongInfo {
            playSong(info: song)
        }
    }
    
    @IBAction func nextButtonAction() {
        DataManager.shared.curIndex += 1
        if let song = DataManager.shared.curSongInfo {
            playSong(info: song)
        }
    }
    
    @IBAction func songListAction() {
        self.pushControllerWithName("SongListInterfaceController", context: nil)
    }
    
    @IBAction func channelListAction() {
        self.pushControllerWithName("ChannelListInterfaceController", context: nil)
    }
    
    override func willActivate() {
        super.willActivate()
        // Refresh UI if the song changed from another screen
        if let currentSong = AudioManager.shared.currentSong,
           let displayedSong = DataManager.shared.curSongInfo,
           currentSong.sid != displayedSong.id {
            playSong(info: displayedSong)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
