#if canImport(UIKit)
import Kingfisher
import RxCocoa
import RxSwift
import UIKit

final class ViewController: UIViewController {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    @IBOutlet private weak var albumLabel: UILabel!
    @IBOutlet private weak var imgView: RoundImageView!
    @IBOutlet private weak var bgImageView: UIImageView!
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var txtView: UITextView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var prevButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    @IBOutlet private weak var downloadButton: UIButton!
    @IBOutlet private weak var likeButton: UIButton!
    @IBOutlet private weak var songTimeLengthLabel: UILabel!
    @IBOutlet private weak var songTimePlayLabel: UILabel!

    private enum Constants {
        static let playButtonImageName = "player_btn_play_normal"
        static let pauseButtonImageName = "player_btn_pause_normal"
    }

    private let viewModel = PlayerViewModel()
    private let disposeBag = DisposeBag()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
        viewModel.viewDidLoad.accept(())
    }

    private func configureUI() {
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgImageView.addSubview(blurView)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
        ])

        playButton.accessibilityLabel = L10n.play
        prevButton.accessibilityLabel = L10n.previousTrack
        nextButton.accessibilityLabel = L10n.nextTrack
        downloadButton.accessibilityLabel = L10n.download
        likeButton.accessibilityLabel = L10n.like
    }

    private func bindViewModel() {
        viewModel.channelName
            .drive(navigationItem.rx.title)
            .disposed(by: disposeBag)

        viewModel.songName
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.artistName
            .drive(artistLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.albumName
            .drive(albumLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.artworkURL
            .drive(onNext: { [weak self] url in
                let placeholder = Asset.image(named: "placeholder")
                self?.imgView.kf.setImage(with: url, placeholder: placeholder)
                self?.bgImageView.kf.setImage(with: url, placeholder: placeholder)
            })
            .disposed(by: disposeBag)

        viewModel.isPlaying
            .drive(onNext: { [weak self] isPlaying in
                guard let self else { return }
                let imageName = isPlaying
                    ? Constants.pauseButtonImageName
                    : Constants.playButtonImageName
                playButton.setImage(Asset.image(named: imageName), for: .normal)
                playButton.accessibilityLabel = isPlaying ? L10n.pause : L10n.play
                isPlaying ? imgView.rotation() : imgView.layer.removeAllAnimations()
            })
            .disposed(by: disposeBag)

        viewModel.songProgress
            .drive(progressView.rx.progress)
            .disposed(by: disposeBag)

        viewModel.currentTimeText
            .drive(songTimePlayLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.totalTimeText
            .drive(songTimeLengthLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel.lyrics
            .drive(txtView.rx.text)
            .disposed(by: disposeBag)

        viewModel.isLoading
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        viewModel.isLoading
            .map { !$0 }
            .drive(onNext: { [weak self] isEnabled in
                self?.playButton.isEnabled = isEnabled
                self?.prevButton.isEnabled = isEnabled
                self?.nextButton.isEnabled = isEnabled
            })
            .disposed(by: disposeBag)

        viewModel.errorMessage
            .emit(onNext: { [weak self] message in
                self?.presentError(message: message)
            })
            .disposed(by: disposeBag)

        viewModel.downloadErrorMessage
            .emit(onNext: { [weak self] message in
                self?.presentDownloadError(message: message)
            })
            .disposed(by: disposeBag)

        playButton.rx.tap
            .bind(to: viewModel.playPauseButtonTapped)
            .disposed(by: disposeBag)

        nextButton.rx.tap
            .bind(to: viewModel.nextButtonTapped)
            .disposed(by: disposeBag)

        prevButton.rx.tap
            .bind(to: viewModel.previousButtonTapped)
            .disposed(by: disposeBag)

        likeButton.rx.tap
            .bind(to: viewModel.likeButtonTapped)
            .disposed(by: disposeBag)

        downloadButton.rx.tap
            .bind(to: viewModel.downloadButtonTapped)
            .disposed(by: disposeBag)
    }

    private func presentError(message: String) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: L10n.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.retry, style: .default) { [weak self] _ in
            self?.viewModel.retryButtonTapped.accept(())
        })
        present(alert, animated: true)
    }

    private func presentDownloadError(message: String) {
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(title: L10n.downloadErrorTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.ok, style: .default))
        present(alert, animated: true)
    }
}

#endif
