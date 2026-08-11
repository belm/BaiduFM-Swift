#if canImport(UIKit)
//
//  DataCenter.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/14.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay

// MARK: - 现代化的数据中心管理类
class DataCenter {
    
    // MARK: - 单例（使用现代化的单例模式）
    static let shared = DataCenter()
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private let userDefaults = UserDefaults.standard
    private var lastRecordedRecentSongID: String?
    
    // MARK: - 响应式属性
    
    // 频道列表信息
    let channelListInfo = BehaviorRelay<[Channel]>(value: [])
    
    // 当前选中的频道 (现在存储整个Channel对象)
    let currentChannel = BehaviorRelay<Channel?>(value: nil)
    
    // 当前频道所有歌曲ID
    let currentAllSongId = BehaviorRelay<[String]>(value: [])
    
    // 当前显示的歌曲信息列表
    let currentSongInfoList = BehaviorRelay<[SongInfo]>(value: [])
    
    // 当前显示的歌曲链接列表  
    let currentSongLinkList = BehaviorRelay<[SongLink]>(value: [])
    
    // 当前播放的歌曲索引
    let currentPlayIndex = BehaviorRelay<Int>(value: 0)
    
    // 当前播放的歌曲信息
    let currentPlayingSong = BehaviorRelay<Song?>(value: nil)
    
    // 喜欢的歌曲列表
    let likedSongs = BehaviorRelay<[Song]>(value: [])
    
    // 最近播放的歌曲列表
    let recentSongs = BehaviorRelay<[Song]>(value: [])
    
    // 已下载的歌曲列表
    let downloadedSongs = BehaviorRelay<[Song]>(value: [])
    
    // 播放状态
    let playbackState = BehaviorRelay<PlaybackState>(value: .idle)
    
    // 显示范围控制
    private let pageSize = 20
    let currentStartIndex = BehaviorRelay<Int>(value: 0)
    let currentEndIndex = BehaviorRelay<Int>(value: 20)
    
    // MARK: - 初始化
    private init() {
        setupBindings()
        loadUserPreferences()
    }
    
    // MARK: - 设置数据绑定
    private func setupBindings() {
        
        // 监听频道变化，自动保存其ID到UserDefaults
        currentChannel
            .compactMap { $0?.id } // 确保频道对象不为nil，并获取其ID
            .skip(1) // 跳过初始值
            .subscribe(onNext: { [weak self] channelId in
                self?.userDefaults.set(channelId, forKey: "LAST_PLAY_CHANNEL_ID")
            })
            .disposed(by: disposeBag)
        
        // 监听AudioManager的播放控制事件
        NotificationCenter.default.rx
            .notification(Notification.Name("AudioManagerPlayNext"))
            .subscribe(onNext: { [weak self] _ in
                self?.playNext()
            })
            .disposed(by: disposeBag)

        AudioManager.shared.playbackState
            .distinctUntilChanged()
            .filter { $0 == .playing }
            .subscribe(onNext: { [weak self] _ in
                guard let self, let song = self.currentPlayingSong.value else { return }
                self.recordRecentPlayback(song: song)
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx
            .notification(Notification.Name("AudioManagerPlayPrevious"))
            .subscribe(onNext: { [weak self] _ in
                self?.playPrevious()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 加载用户偏好设置
    private func loadUserPreferences() {
        // 加载上次播放的频道ID，后续在频道列表加载后会用此ID来设置currentChannel
        if let savedChannelId = userDefaults.string(forKey: "LAST_PLAY_CHANNEL_ID") {
            // 临时存储，等待频道列表加载
            let initialChannel = Channel(
                id: savedChannelId,
                name: L10n.loading,
                order: 0,
                cate_id: "",
                cate: "",
                cate_order: 0,
                pv_order: 0
            )
            currentChannel.accept(initialChannel)
        }
    }
    
    // MARK: - 计算属性：当前显示的歌曲ID列表
    var currentDisplaySongIds: Observable<[String]> {
        return Observable.combineLatest(
            currentAllSongId,
            currentStartIndex,
            currentEndIndex
        )
        .map { (allIds, start, end) -> [String] in
            let validEnd = min(end, allIds.count)
            let validStart = max(0, min(start, validEnd))
            return Array(allIds[validStart..<validEnd])
        }
    }
    
    // MARK: - 数据加载方法
    
    /// 加载频道列表
    func loadChannelList() -> Observable<Void> {
        return NetworkManager.shared.getChannelList()
            .do(onNext: { [weak self] channels in
                guard let self = self else { return }
                self.channelListInfo.accept(channels)
                
                // 列表加载后，根据保存的ID或默认值更新currentChannel
                if let savedChannelId = self.userDefaults.string(forKey: "LAST_PLAY_CHANNEL_ID"),
                   let channelToRestore = channels.first(where: { $0.id == savedChannelId }) {
                    self.currentChannel.accept(channelToRestore)
                } else if let defaultChannel = channels.first {
                    self.currentChannel.accept(defaultChannel) // 如果没有保存的，则使用列表的第一个
                }
            })
            .map { _ in () }
    }
    
    /// 加载指定频道的歌曲列表
    func loadSongList() -> Observable<Void> {
        // 从currentChannel获取ID
        guard let channelId = currentChannel.value?.id else {
            return .error(NSError(domain: "DataCenter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Channel ID is missing"]))
        }
        
        return NetworkManager.shared.getSongList(channelId: channelId)
            .do(onNext: { [weak self] songIds in
                self?.currentAllSongId.accept(songIds)
                self?.resetDisplayRange()
            })
            .map { _ in () }
    }
    
    /// 加载歌曲详细信息
    func loadSongDetails() -> Observable<Void> {
        return currentDisplaySongIds
            .take(1)
            .flatMap { songIds -> Observable<([SongInfo], [SongLink])> in
                let infoObservable = NetworkManager.shared.getSongInfo(songIds: songIds)
                let linkObservable = NetworkManager.shared.getSongLinks(songIds: songIds)
                return Observable.zip(infoObservable, linkObservable)
            }
            .do(onNext: { [weak self] (infoList, linkList) in
                self?.currentSongInfoList.accept(infoList)
                self?.currentSongLinkList.accept(linkList)
            })
            .map { _ in () }
    }
    
    /// 加载喜欢的歌曲列表
    func loadLikedSongs() {
        let songs = dbSongList.getAllLike() ?? []
        likedSongs.accept(songs)
    }
    
    /// 加载最近播放的歌曲列表
    func loadRecentSongs() {
        let songs = dbSongList.getAllRecent() ?? []
        recentSongs.accept(songs)
    }
    
    /// 加载已下载的歌曲列表
    func loadDownloadedSongs() {
        let songs = dbSongList.getAllDownload() ?? []
        downloadedSongs.accept(songs)
    }

    func toggleLike(song: Song) {
        let songList = dbSongList
        guard songList.upsert(song: song) else { return }

        let newStatus = songList.get(sid: song.sid)?.is_like == 1 ? 0 : 1
        guard songList.updateLikeStatus(sid: song.sid, status: newStatus) else { return }
        song.is_like = newStatus
        loadLikedSongs()
        currentPlayingSong.accept(song)
    }

    // MARK: - 播放控制方法
    
    /// 播放指定索引的歌曲
    func playSong(at index: Int) {
        guard let song = song(at: index) else { return }
        currentPlayIndex.accept(index)
        currentPlayingSong.accept(song)
        
        if let url = playbackURL(for: song) {
            AudioManager.shared.play(from: url, song: song)
        } else {
            AudioManager.shared.reportPlaybackFailure(L10n.insecureConnectionBlocked)
        }
    }

    /// Prepares a song for an explicit play action without starting audio.
    func prepareSong(at index: Int) {
        guard let song = song(at: index), let url = playbackURL(for: song) else { return }
        currentPlayIndex.accept(index)
        currentPlayingSong.accept(song)
        AudioManager.shared.prepare(from: url, song: song)
    }

    /// Restores the last session paused so launch never causes unexpected audio.
    func restorePlaybackSession() -> Bool {
        guard let snapshot = PlaybackSessionStore.shared.load() else { return false }
        let song = hydrateStoredState(for: snapshot.song.makeSong())
        guard let url = playbackURL(for: song) else {
            PlaybackSessionStore.shared.clear()
            return false
        }

        if let index = currentSongInfoList.value.firstIndex(where: { $0.songId == song.sid }) {
            currentPlayIndex.accept(index)
        }
        currentPlayingSong.accept(song)
        let safePosition = PlaybackRestorePolicy.safePosition(snapshot.position, duration: song.time)
        AudioManager.shared.prepare(from: url, song: song, position: safePosition)
        return true
    }

    /// Aligns next and previous navigation after the catalog finishes loading.
    func alignCurrentPlayingSongWithLoadedList() {
        guard let songID = currentPlayingSong.value?.sid else { return }
        let index = currentSongInfoList.value.firstIndex(where: { $0.songId == songID }) ?? -1
        currentPlayIndex.accept(index)
    }
    
    /// 直接播放一个Song对象
    func playSong(song: Song) {
        // 检查这首歌是否在当前列表中
        if let index = currentSongInfoList.value.firstIndex(where: { $0.songId == song.sid }) {
            // 如果在，就用现有的列表逻辑播放
            playSong(at: index)
        } else {
            // 如果不在，直接播放该歌曲对象
            currentPlayingSong.accept(song)
            if let url = playbackURL(for: song) {
                AudioManager.shared.play(from: url, song: song)
            } else {
                AudioManager.shared.reportPlaybackFailure(L10n.insecureConnectionBlocked)
            }
        }
    }
    
    /// 播放下一首
    func playNext() {
        let currentIndex = currentPlayIndex.value
        let nextIndex = currentIndex + 1
        
        if nextIndex < currentSongInfoList.value.count {
            playSong(at: nextIndex)
        } else {
            // 如果是最后一首，加载更多歌曲
            loadMoreSongs()
                .subscribe(onNext: { [weak self] in
                    self?.playSong(at: nextIndex)
                })
                .disposed(by: disposeBag)
        }
    }
    
    /// 播放上一首
    func playPrevious() {
        let currentIndex = currentPlayIndex.value
        let previousIndex = currentIndex - 1
        
        if previousIndex >= 0 {
            playSong(at: previousIndex)
        }
    }
    
    // MARK: - 分页控制方法
    
    /// 重置显示范围
    private func resetDisplayRange() {
        currentStartIndex.accept(0)
        currentEndIndex.accept(pageSize)
    }
    
    /// 加载更多歌曲
    func loadMoreSongs() -> Observable<Void> {
        let allIds = currentAllSongId.value
        let currentEnd = currentEndIndex.value
        
        if currentEnd < allIds.count {
            let newEnd = min(currentEnd + pageSize, allIds.count)
            currentEndIndex.accept(newEnd)
            return loadSongDetails()
        }
        
        return Observable.just(())
    }
    
    // MARK: - 私有方法
    
    private func playbackURL(for song: Song) -> URL? {
        DownloadManager.shared.getLocalURL(for: song)
            ?? NetworkManager.shared.secureContentURL(from: song.song_url)
    }

    private func song(at index: Int) -> Song? {
        guard index >= 0,
              index < currentSongInfoList.value.count,
              index < currentSongLinkList.value.count else { return nil }
        let info = currentSongInfoList.value[index]
        let link = currentSongLinkList.value[index]
        return hydrateStoredState(for: Song(
            sid: link.songId,
            name: info.name,
            url: link.songLink,
            pic_url: info.picUrl,
            lrc_url: link.lrcLink,
            artist: info.artistName,
            album: info.albumName,
            format: link.format,
            time: link.time
        ))
    }

    private func hydrateStoredState(for song: Song) -> Song {
        guard let storedSong = dbSongList.get(sid: song.sid) else { return song }
        song.is_like = storedSong.is_like
        song.is_dl = storedSong.is_dl
        song.dl_file = storedSong.dl_file
        song.is_recent = storedSong.is_recent
        return song
    }

    private func recordRecentPlayback(song: Song) {
        guard lastRecordedRecentSongID != song.sid else { return }
        let songList = dbSongList
        guard songList.upsert(song: song), songList.addRecentSong(songId: song.sid) else { return }
        lastRecordedRecentSongID = song.sid
        song.is_recent = 1
        loadRecentSongs()
    }
    
    /// 清空喜欢的歌曲列表
    func clearLikedSongs() {
        if dbSongList.clearLikeList() {
            // 如果成功，重新加载以更新UI绑定的数据流
            loadLikedSongs()
        }
    }
    
    /// 从喜欢列表中移除单个歌曲
    func removeSongFromLikes(songId: String) {
        if dbSongList.deleteLikeSong(songId: songId) {
            // 如果成功，重新加载以更新UI绑定的数据流
            loadLikedSongs()
        }
    }
    
    /// 清空最近播放的歌曲列表
    func clearRecentSongs() {
        if dbSongList.cleanRecentList() {
            loadRecentSongs()
        }
    }
    
    /// 从最近播放列表中移除单个歌曲
    func removeSongFromRecents(songId: String) {
        if dbSongList.deleteRecentSong(songId: songId) {
            loadRecentSongs()
        }
    }
    
    /// 清空所有下载的歌曲
    func clearAllDownloads() {
        do {
            try DownloadManager.shared.removeAllDownloads()
            loadDownloadedSongs()
        } catch {
            print("Failed to clear downloads: \(error.localizedDescription)")
        }
    }
    
    /// 移除单个下载的歌曲
    func removeDownloadedSong(song: Song) {
        DownloadManager.shared.deleteDownload(taskId: song.sid)
            .subscribe(
                onError: { error in
                    print("Failed to remove download: \(error.localizedDescription)")
                },
                onCompleted: { [weak self] in self?.loadDownloadedSongs() }
            )
            .disposed(by: disposeBag)
    }
}

// MARK: - 数据库操作扩展
extension DataCenter {
    
    // 数据库操作对象
    var dbSongList: SongList {
        return SongList()
    }
}

#endif
