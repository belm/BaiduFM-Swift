#if canImport(UIKit)
import Foundation
import RxCocoa
import RxRelay
import RxSwift

final class PlayerViewModel {
    private let disposeBag = DisposeBag()
    private let dataCenter = DataCenter.shared
    private let audioManager = AudioManager.shared
    private let parsedLyrics = BehaviorRelay<[(lrc: String, time: Int)]>(value: [])

    // MARK: Inputs

    let viewDidLoad = PublishRelay<Void>()
    let playPauseButtonTapped = PublishRelay<Void>()
    let nextButtonTapped = PublishRelay<Void>()
    let previousButtonTapped = PublishRelay<Void>()
    let likeButtonTapped = PublishRelay<Void>()
    let downloadButtonTapped = PublishRelay<Void>()

    // MARK: Outputs

    let songName: Driver<String>
    let artistName: Driver<String>
    let albumName: Driver<String>
    let artworkURL: Driver<URL?>
    let isPlaying: Driver<Bool>
    let songProgress: Driver<Float>
    let currentTimeText: Driver<String>
    let totalTimeText: Driver<String>
    let lyrics: Driver<String>
    let channelName: Driver<String>

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
                return URL(string: path)
            }
            .distinctUntilChanged { $0 == $1 }

        isPlaying = audioManager.playbackState
            .map { $0 == .playing }
            .asDriver(onErrorJustReturn: false)

        songProgress = audioManager.progress.asDriver()

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

        bindInputs()
        bindLyrics()
    }

    private func bindInputs() {
        viewDidLoad
            .flatMapLatest { [dataCenter] _ -> Observable<Void> in
                let channelLoad: Observable<Void> = dataCenter.channelListInfo.value.isEmpty
                    ? dataCenter.loadChannelList()
                    : .just(())

                return channelLoad
                    .flatMapLatest { dataCenter.loadSongList() }
                    .flatMapLatest { dataCenter.loadSongDetails() }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [dataCenter] in
                    guard !dataCenter.currentSongInfoList.value.isEmpty else { return }
                    dataCenter.playSong(at: 0)
                },
                onError: { error in
                    print("Initial song loading failed: \(error.localizedDescription)")
                }
            )
            .disposed(by: disposeBag)

        playPauseButtonTapped
            .subscribe(onNext: { [audioManager] in
                audioManager.playbackState.value == .playing
                    ? audioManager.pause()
                    : audioManager.resume()
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
            .flatMapLatest { song in
                DownloadManager.shared.startDownload(song: song)
                    .ignoreElements()
                    .andThen(.just(song))
                    .catch { error in
                        print("Download failed: \(error.localizedDescription)")
                        return .empty()
                    }
            }
            .subscribe(onNext: { [dataCenter] song in
                dataCenter.markDownloaded(song: song)
            })
            .disposed(by: disposeBag)
    }

    private func bindLyrics() {
        dataCenter.currentPlayingSong
            .compactMap { $0 }
            .distinctUntilChanged { $0.sid == $1.sid }
            .flatMapLatest { song -> Observable<String> in
                guard !song.lrc_url.isEmpty else { return .just("") }
                let url = song.lrc_url.hasPrefix("http") ? song.lrc_url : http_song_lrc + song.lrc_url
                return NetworkManager.shared.getLyrics(url: url)
                    .catchAndReturn("")
            }
            .map(Common.praseSongLrc)
            .bind(to: parsedLyrics)
            .disposed(by: disposeBag)
    }
}

#endif
