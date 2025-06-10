import Foundation
import RxSwift
import RxCocoa
import UIKit

class PlayerViewModel {
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private let dataCenter = DataCenter.shared
    private let audioManager = AudioManager.shared
    private let parsedLrc = BehaviorRelay<[(lrc: String, time: Int)]>(value: [])
    
    // MARK: - 输入 (Inputs)
    let viewDidLoad = PublishRelay<Void>()
    let playPauseButtonTapped = PublishRelay<Void>()
    let nextButtonTapped = PublishRelay<Void>()
    let prevButtonTapped = PublishRelay<Void>()
    let likeButtonTapped = PublishRelay<Void>()
    let downloadButtonTapped = PublishRelay<Void>()

    // MARK: - 输出 (Outputs)
    let songName: Driver<String>
    let artistName: Driver<String>
    let albumName: Driver<String>
    let albumImage: Driver<UIImage?>
    let backgroundImage: Driver<UIImage?>
    let isPlaying: Driver<Bool>
    let songProgress: Driver<Float>
    let currentTimeText: Driver<String>
    let totalTimeText: Driver<String>
    let lyrics: Driver<String>
    let nextLyricLine: Driver<String>
    let isLikeButtonEnabled: Driver<Bool>
    let isDownloadButtonEnabled: Driver<Bool>
    
    init() {
        // MARK: - Aliases
        let audioManager = self.audioManager
        let dataCenter = self.dataCenter
        
        // MARK: - 输出绑定
        
        let currentSong = dataCenter.currentPlayingSong.asDriver(onErrorJustReturn: nil).compactMap { $0 }
        
        songName = currentSong.map { $0.name }.distinctUntilChanged()
        artistName = currentSong.map { "- \($0.artist) -" }.distinctUntilChanged()
        albumName = currentSong.map { $0.album }.distinctUntilChanged()
        
        albumImage = currentSong
            .flatMapLatest { song -> Driver<UIImage?> in
                guard let url = URL(string: song.pic_url) else { return .just(nil) }
                return ImageLoader.loadImage(from: url)
                    .asDriver(onErrorJustReturn: nil)
            }
        
        backgroundImage = albumImage
        
        isPlaying = audioManager.playbackState
            .map { $0 == .playing }
            .asDriver(onErrorJustReturn: false)
            
        songProgress = audioManager.progress.asDriver()
        
        currentTimeText = audioManager.currentTime
            .map { Common.getMinuteDisplay(Int($0)) }
            .asDriver(onErrorJustReturn: "00:00")
            
        totalTimeText = audioManager.duration
            .map { Common.getMinuteDisplay(Int($0)) }
            .asDriver(onErrorJustReturn: "00:00")
            
        let currentLrcTuple = Observable.combineLatest(audioManager.currentTime, self.parsedLrc)
            .map { (time, lrcArray) -> (String, String) in
                return Common.currentLrcByTime(curLength: Int(time), lrcArray: lrcArray)
            }
            .asDriver(onErrorJustReturn: ("暂无歌词", ""))
            
        lyrics = currentLrcTuple.map { $0.0 }
        nextLyricLine = currentLrcTuple.map { $0.1 }
        
        isLikeButtonEnabled = .just(true)
        isDownloadButtonEnabled = .just(true)
        
        // MARK: - 输入处理
        
        let songLoading = viewDidLoad
            .flatMapLatest { [dataCenter] _ -> Observable<Void> in
                return dataCenter.loadSongList(channelId: dataCenter.currentChannel.value)
            }
            .flatMapLatest { [dataCenter] _ -> Observable<Void> in
                return dataCenter.loadSongDetails()
            }
            .share()

        songLoading
            .subscribe(onNext: { [dataCenter] _ in
                dataCenter.playSong(at: 0)
            })
            .disposed(by: disposeBag)
        
        currentSong
            .asObservable()
            .flatMapLatest { song -> Observable<String> in
                guard !song.lrc_url.isEmpty else { return .just("") }
                // 使用现代化的 async/await 方法
                return Observable.create { observer in
                    Task {
                        do {
                            let lrcString = try await HttpRequest.getLrcAsync(lrcUrl: song.lrc_url)
                            observer.onNext(lrcString)
                            observer.onCompleted()
                        } catch {
                            observer.onNext("") // 出错时返回空歌词
                            observer.onCompleted()
                        }
                    }
                    return Disposables.create()
                }
            }
            .map { lrcString in
                Common.praseSongLrc(lrc: lrcString)
            }
            .bind(to: self.parsedLrc)
            .disposed(by: disposeBag)
            
        playPauseButtonTapped
            .subscribe(onNext: {
                if audioManager.playbackState.value == .playing {
                    audioManager.pause()
                } else {
                    audioManager.resume()
                }
            })
            .disposed(by: disposeBag)
            
        nextButtonTapped
            .subscribe(onNext: {
                dataCenter.playNext()
            })
            .disposed(by: disposeBag)
            
        prevButtonTapped
            .subscribe(onNext: {
                dataCenter.playPrevious()
            })
            .disposed(by: disposeBag)
            
        likeButtonTapped.subscribe(onNext: { print("喜欢按钮被点击") }).disposed(by: disposeBag)
        downloadButtonTapped.subscribe(onNext: { print("下载按钮被点击") }).disposed(by: disposeBag)
    }
}

// 简单的图片加载器，用于演示
class ImageLoader {
    static func loadImage(from url: URL) -> Observable<UIImage?> {
        return Observable.create { observer in
            let task = URLSession.shared.dataTask(with: url) { data, _, error in
                if error != nil {
                    observer.onNext(nil)
                } else if let data = data, let image = UIImage(data: data) {
                    observer.onNext(image)
                } else {
                    observer.onNext(nil)
                }
                observer.onCompleted()
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .observe(on: MainScheduler.instance)
    }
} 