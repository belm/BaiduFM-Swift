#if canImport(UIKit)
import Foundation
import RxCocoa
import RxRelay
import RxSwift

enum PlayerDownloadState: Equatable {
    case available
    case waiting
    case downloading(Int)
    case paused
    case completed
    case failed
}

final class PlayerViewModel {
    private enum InitialLoadResult {
        case success
        case failure(String)
    }

    private let disposeBag = DisposeBag()
    private let dataCenter = DataCenter.shared
    private let audioManager = AudioManager.shared
    private let parsedLyrics = BehaviorRelay<[(lrc: String, time: Int)]>(value: [])
    private let initialLoadInProgress = BehaviorRelay<Bool>(value: false)
    private let errorRelay = PublishRelay<String>()
    private let downloadErrorRelay = PublishRelay<String>()
    private var didAttemptLaunchRestore = false
    private var restoredSessionOnLaunch = false

    // MARK: Inputs

    let viewDidLoad = PublishRelay<Void>()
    let playPauseButtonTapped = PublishRelay<Void>()
    let nextButtonTapped = PublishRelay<Void>()
    let previousButtonTapped = PublishRelay<Void>()
    let likeButtonTapped = PublishRelay<Void>()
    let downloadButtonTapped = PublishRelay<Void>()
    let retryButtonTapped = PublishRelay<Void>()
    let seekRequested = PublishRelay<Float>()

    // MARK: Outputs

    let songName: Driver<String>
    let artistName: Driver<String>
    let albumName: Driver<String>
    let artworkURL: Driver<URL?>
    let isPlaying: Driver<Bool>
    let isLiked: Driver<Bool>
    let downloadState: Driver<PlayerDownloadState>
    let songProgress: Driver<Float>
    let durationSeconds: Driver<TimeInterval>
    let currentTimeText: Driver<String>
    let totalTimeText: Driver<String>
    let lyrics: Driver<String>
    let channelName: Driver<String>
    let isLoading: Driver<Bool>
    let errorMessage: Signal<String>
    let downloadErrorMessage: Signal<String>

    init() {
        let currentSong = dataCenter.currentPlayingSong
            .asDriver(onErrorJustReturn: nil)

        songName = currentSong
            .map { $0?.name ?? L10n.noSong }
            .distinctUntilChanged()

        artistName = currentSong
            .map { song in
                guard let artist = song?.artist, !artist.isEmpty else { return "" }
                return "– \(artist) –"
            }
            .distinctUntilChanged()

        albumName = currentSong
            .map { $0?.album ?? "" }
            .distinctUntilChanged()

        artworkURL = currentSong
            .map { song in
                guard let path = song?.pic_url, !path.isEmpty else { return nil }
                return NetworkManager.shared.secureContentURL(from: path)
            }
            .distinctUntilChanged { $0 == $1 }

        isPlaying = audioManager.playbackState
            .map { $0 == .playing }
            .asDriver(onErrorJustReturn: false)

        isLiked = Observable.combineLatest(
            dataCenter.currentPlayingSong,
            dataCenter.likedSongs
        ) { song, likedSongs in
            guard let song else { return false }
            return likedSongs.contains { $0.sid == song.sid }
        }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: false)

        downloadState = Observable.combineLatest(
            dataCenter.currentPlayingSong,
            DownloadManager.shared.downloadTasks
        ) { song, tasks -> PlayerDownloadState in
            guard let song, let task = tasks.first(where: { $0.id == song.sid }) else {
                return .available
            }
            switch task.status.value {
            case .waiting:
                return .waiting
            case .downloading:
                return .downloading(Int(task.progress.value * 100))
            case .paused:
                return .paused
            case .completed:
                return .completed
            case .failed, .cancelled:
                return .failed
            }
        }
        .distinctUntilChanged()
        .asDriver(onErrorJustReturn: .available)

        songProgress = audioManager.progress.asDriver()
        durationSeconds = audioManager.duration.asDriver()

        currentTimeText = audioManager.currentTime
            .map { Common.getMinuteDisplay(seconds: Int($0)) }
            .asDriver(onErrorJustReturn: "00:00")

        totalTimeText = audioManager.duration
            .map { Common.getMinuteDisplay(seconds: Int($0)) }
            .asDriver(onErrorJustReturn: "00:00")

        lyrics = Observable.combineLatest(audioManager.currentTime, parsedLyrics)
            .map { time, entries in
                let current = Common.currentLrcByTime(curLength: Int(time), lrcArray: entries).0
                return current.isEmpty ? L10n.noLyrics : current
            }
            .asDriver(onErrorJustReturn: L10n.noLyrics)

        channelName = dataCenter.currentChannel
            .map { $0?.name ?? L10n.appName }
            .asDriver(onErrorJustReturn: L10n.appName)

        isLoading = Observable.combineLatest(
            initialLoadInProgress,
            audioManager.playbackState.map { $0 == .loading },
            dataCenter.currentPlayingSong
        ) { isCatalogLoading, isPlayerLoading, song in
            isPlayerLoading || (isCatalogLoading && song == nil)
        }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)

        errorMessage = errorRelay.asSignal()
        downloadErrorMessage = downloadErrorRelay.asSignal()

        bindInputs()
        bindLyrics()
    }

    private func bindInputs() {
        Observable.merge(viewDidLoad.asObservable(), retryButtonTapped.asObservable())
            .do(onNext: { [weak self, dataCenter, initialLoadInProgress] in
                dataCenter.loadLikedSongs()
                if let self, !self.didAttemptLaunchRestore {
                    self.didAttemptLaunchRestore = true
                    self.restoredSessionOnLaunch = dataCenter.currentPlayingSong.value != nil
                        || dataCenter.restorePlaybackSession()
                }
                initialLoadInProgress.accept(true)
            })
            .flatMapLatest { [dataCenter] _ -> Observable<InitialLoadResult> in
                let channelLoad: Observable<Void> = dataCenter.channelListInfo.value.isEmpty
                    ? dataCenter.loadChannelList()
                    : .just(())

                return channelLoad
                    .flatMapLatest { dataCenter.loadSongList() }
                    .flatMapLatest { dataCenter.loadSongDetails() }
                    .map { InitialLoadResult.success }
                    .catch { error in
                        .just(.failure(error.localizedDescription))
                    }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self, dataCenter, initialLoadInProgress, errorRelay] result in
                initialLoadInProgress.accept(false)
                switch result {
                case .success:
                    guard !dataCenter.currentSongInfoList.value.isEmpty else {
                        errorRelay.accept(L10n.noData)
                        return
                    }
                    if self?.restoredSessionOnLaunch == true {
                        dataCenter.alignCurrentPlayingSongWithLoadedList()
                    } else {
                        dataCenter.prepareSong(at: 0)
                    }
                case .failure(let message):
                    if dataCenter.currentPlayingSong.value == nil {
                        errorRelay.accept(message.isEmpty ? L10n.loadSongsFailed : message)
                    }
                }
            })
            .disposed(by: disposeBag)

        audioManager.playbackError
            .bind(to: errorRelay)
            .disposed(by: disposeBag)

        playPauseButtonTapped
            .subscribe(onNext: { [audioManager, dataCenter] in
                switch audioManager.playbackState.value {
                case .playing:
                    audioManager.pause()
                case .error, .idle, .stopped:
                    if let song = dataCenter.currentPlayingSong.value {
                        dataCenter.playSong(song: song)
                    }
                case .loading, .paused:
                    audioManager.resume()
                }
            })
            .disposed(by: disposeBag)

        seekRequested
            .subscribe(onNext: { [audioManager] progress in
                let clampedProgress = min(max(progress, 0), 1)
                audioManager.seek(to: audioManager.duration.value * Double(clampedProgress))
            })
            .disposed(by: disposeBag)

        nextButtonTapped
            .subscribe(onNext: { [dataCenter] in dataCenter.playNext() })
            .disposed(by: disposeBag)

        previousButtonTapped
            .subscribe(onNext: { [dataCenter] in dataCenter.playPrevious() })
            .disposed(by: disposeBag)

        likeButtonTapped
            .compactMap { [dataCenter] in dataCenter.currentPlayingSong.value }
            .subscribe(onNext: { [dataCenter] song in
                dataCenter.toggleLike(song: song)
            })
            .disposed(by: disposeBag)

        downloadButtonTapped
            .compactMap { [dataCenter] in dataCenter.currentPlayingSong.value }
            .subscribe(onNext: { [weak self] song in
                guard let self else { return }
                guard !DownloadManager.shared.isDownloaded(song: song) else { return }
                DownloadManager.shared.startDownload(song: song)
                    .subscribe(
                        onError: { [weak self] error in
                            self?.downloadErrorRelay.accept(error.localizedDescription)
                        },
                        onCompleted: {}
                    )
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
    }

    private func bindLyrics() {
        dataCenter.currentPlayingSong
            .compactMap { $0 }
            .distinctUntilChanged { $0.sid == $1.sid }
            .flatMapLatest { song -> Observable<String> in
                guard !song.lrc_url.isEmpty else { return .just("") }
                return NetworkManager.shared.getLyrics(url: song.lrc_url)
                    .catchAndReturn("")
            }
            .map(Common.praseSongLrc)
            .bind(to: parsedLyrics)
            .disposed(by: disposeBag)
    }
}

#endif
