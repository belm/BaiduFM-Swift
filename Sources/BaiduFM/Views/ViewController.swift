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

    private let viewModel = PlayerViewModel()
    private let disposeBag = DisposeBag()
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let gradientView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let artworkContainer = UIView()
    private let timelineSlider = UISlider()
    private let playerActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let lyricsCard = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))

    private var isSeeking = false
    private var latestDuration: TimeInterval = 0
    private var previousDownloadState: PlayerDownloadState?

    override func viewDidLoad() {
        super.viewDidLoad()
        rebuildPlayerInterface()
        configureAccessibility()
        bindViewModel()
        bindControls()
        viewModel.viewDidLoad.accept(())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = gradientView.bounds
        artworkContainer.layer.shadowPath = UIBezierPath(
            roundedRect: artworkContainer.bounds,
            cornerRadius: ExperienceTheme.artworkCornerRadius
        ).cgPath
    }

    private func rebuildPlayerInterface() {
        let retainedViews: [UIView] = [
            bgImageView,
            imgView,
            nameLabel,
            artistLabel,
            albumLabel,
            txtView,
            playButton,
            prevButton,
            nextButton,
            downloadButton,
            likeButton,
            songTimePlayLabel,
            songTimeLengthLabel,
            progressView,
        ]

        NSLayoutConstraint.deactivate(view.constraints)
        retainedViews.forEach { component in
            NSLayoutConstraint.deactivate(component.constraints)
            component.removeFromSuperview()
            component.translatesAutoresizingMaskIntoConstraints = false
        }
        view.subviews.forEach { $0.removeFromSuperview() }

        view.alpha = 1
        view.backgroundColor = .black
        configureNavigationAppearance()

        bgImageView.contentMode = .scaleAspectFill
        bgImageView.clipsToBounds = true
        bgImageView.alpha = 0.64
        view.addSubview(bgImageView)

        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundBlurView)

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0.12).cgColor,
            UIColor.black.withAlphaComponent(0.38).cgColor,
            UIColor.black.withAlphaComponent(0.88).cgColor,
        ]
        gradientLayer.locations = [0, 0.48, 1]
        gradientView.layer.addSublayer(gradientLayer)
        view.addSubview(gradientView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        configureArtwork()
        configureIdentity()
        configureTimeline()
        configureTransportControls()
        configureActionControls()
        configureLyrics()

        NSLayoutConstraint.activate([
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: ExperienceTheme.horizontalMargin),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -ExperienceTheme.horizontalMargin),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(ExperienceTheme.horizontalMargin * 2)),
        ])
    }

    private func configureNavigationAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.preferredFont(forTextStyle: .headline),
        ]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        if let channelButton = navigationItem.rightBarButtonItem?.customView as? UIButton {
            var configuration = UIButton.Configuration.plain()
            configuration.title = L10n.channels
            configuration.image = UIImage(systemName: "dot.radiowaves.left.and.right")
            configuration.imagePadding = 6
            configuration.baseForegroundColor = .white
            channelButton.configuration = configuration
            channelButton.accessibilityLabel = L10n.channels
            channelButton.accessibilityHint = L10n.chooseChannelHint
        }
    }

    private func configureArtwork() {
        artworkContainer.translatesAutoresizingMaskIntoConstraints = false
        artworkContainer.layer.shadowColor = UIColor.black.cgColor
        artworkContainer.layer.shadowOpacity = 0.34
        artworkContainer.layer.shadowRadius = 24
        artworkContainer.layer.shadowOffset = CGSize(width: 0, height: 14)
        contentStack.addArrangedSubview(artworkContainer)

        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = ExperienceTheme.artworkCornerRadius
        imgView.layer.borderWidth = 0
        artworkContainer.addSubview(imgView)

        let proportionalWidth = artworkContainer.widthAnchor.constraint(
            equalTo: contentStack.widthAnchor,
            multiplier: 0.78
        )
        proportionalWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            proportionalWidth,
            artworkContainer.widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            artworkContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            artworkContainer.heightAnchor.constraint(equalTo: artworkContainer.widthAnchor),
            imgView.leadingAnchor.constraint(equalTo: artworkContainer.leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: artworkContainer.trailingAnchor),
            imgView.topAnchor.constraint(equalTo: artworkContainer.topAnchor),
            imgView.bottomAnchor.constraint(equalTo: artworkContainer.bottomAnchor),
        ])
    }

    private func configureIdentity() {
        let identityStack = UIStackView(arrangedSubviews: [nameLabel, artistLabel, albumLabel])
        identityStack.axis = .vertical
        identityStack.alignment = .center
        identityStack.spacing = 3
        identityStack.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = .preferredFont(forTextStyle: .title2)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = .white
        nameLabel.numberOfLines = 2
        nameLabel.textAlignment = .center

        artistLabel.font = .preferredFont(forTextStyle: .body)
        artistLabel.adjustsFontForContentSizeCategory = true
        artistLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        artistLabel.numberOfLines = 1

        albumLabel.isHidden = false
        albumLabel.font = .preferredFont(forTextStyle: .caption1)
        albumLabel.adjustsFontForContentSizeCategory = true
        albumLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        albumLabel.numberOfLines = 1

        contentStack.addArrangedSubview(identityStack)
        identityStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    }

    private func configureTimeline() {
        timelineSlider.minimumValue = 0
        timelineSlider.maximumValue = 1
        timelineSlider.minimumTrackTintColor = .white
        timelineSlider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.28)
        timelineSlider.setThumbImage(
            UIImage(
                systemName: "circle.fill",
                withConfiguration: ExperienceTheme.makeSymbolConfiguration(pointSize: 15)
            ),
            for: .normal
        )
        timelineSlider.translatesAutoresizingMaskIntoConstraints = false

        [songTimePlayLabel, songTimeLengthLabel].forEach { label in
            label?.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            label?.textColor = UIColor.white.withAlphaComponent(0.7)
            label?.adjustsFontForContentSizeCategory = true
        }

        let spacer = UIView()
        let timeStack = UIStackView(arrangedSubviews: [songTimePlayLabel, spacer, songTimeLengthLabel])
        timeStack.axis = .horizontal
        timeStack.alignment = .center

        let timelineStack = UIStackView(arrangedSubviews: [timelineSlider, timeStack])
        timelineStack.axis = .vertical
        timelineStack.spacing = 2
        timelineStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(timelineStack)
        timelineStack.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
    }

    private func configureTransportControls() {
        configureTransportButton(prevButton, systemName: "backward.fill", pointSize: 25)
        configureTransportButton(nextButton, systemName: "forward.fill", pointSize: 25)

        var playConfiguration = UIButton.Configuration.filled()
        playConfiguration.image = UIImage(systemName: "play.fill")
        playConfiguration.preferredSymbolConfigurationForImage = ExperienceTheme.makeSymbolConfiguration(pointSize: 28)
        playConfiguration.baseForegroundColor = .white
        playConfiguration.baseBackgroundColor = ExperienceTheme.accent
        playConfiguration.cornerStyle = .capsule
        playButton.configuration = playConfiguration
        playButton.layer.shadowColor = ExperienceTheme.accent.cgColor
        playButton.layer.shadowOpacity = 0.34
        playButton.layer.shadowRadius = 14
        playButton.layer.shadowOffset = CGSize(width: 0, height: 7)

        playerActivityIndicator.color = .white
        playerActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        playButton.addSubview(playerActivityIndicator)

        let controls = UIStackView(arrangedSubviews: [prevButton, playButton, nextButton])
        controls.axis = .horizontal
        controls.alignment = .center
        controls.distribution = .equalCentering
        controls.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(controls)

        NSLayoutConstraint.activate([
            controls.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.68),
            prevButton.widthAnchor.constraint(equalToConstant: 52),
            prevButton.heightAnchor.constraint(equalToConstant: 52),
            playButton.widthAnchor.constraint(equalToConstant: 68),
            playButton.heightAnchor.constraint(equalToConstant: 68),
            nextButton.widthAnchor.constraint(equalToConstant: 52),
            nextButton.heightAnchor.constraint(equalToConstant: 52),
            playerActivityIndicator.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
            playerActivityIndicator.centerYAnchor.constraint(equalTo: playButton.centerYAnchor),
        ])
    }

    private func configureTransportButton(_ button: UIButton, systemName: String, pointSize: CGFloat) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: systemName)
        configuration.preferredSymbolConfigurationForImage = ExperienceTheme.makeSymbolConfiguration(pointSize: pointSize)
        configuration.baseForegroundColor = .white
        button.configuration = configuration
    }

    private func configureActionControls() {
        configureActionButton(likeButton, title: L10n.like, systemName: "heart")
        configureActionButton(downloadButton, title: L10n.download, systemName: "arrow.down.circle")

        let actions = UIStackView(arrangedSubviews: [likeButton, downloadButton])
        actions.axis = .horizontal
        actions.alignment = .center
        actions.distribution = .fillEqually
        actions.spacing = 24
        actions.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(actions)

        NSLayoutConstraint.activate([
            actions.widthAnchor.constraint(equalTo: contentStack.widthAnchor, multiplier: 0.72),
            likeButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 58),
            downloadButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 58),
        ])
    }

    private func configureActionButton(_ button: UIButton, title: String, systemName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: systemName)
        configuration.imagePlacement = .top
        configuration.imagePadding = 5
        configuration.preferredSymbolConfigurationForImage = ExperienceTheme.makeSymbolConfiguration(pointSize: 21)
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.86)
        button.configuration = configuration
    }

    private func configureLyrics() {
        lyricsCard.translatesAutoresizingMaskIntoConstraints = false
        lyricsCard.layer.cornerRadius = ExperienceTheme.cardCornerRadius
        lyricsCard.clipsToBounds = true
        contentStack.addArrangedSubview(lyricsCard)

        txtView.backgroundColor = .clear
        txtView.isEditable = false
        txtView.isSelectable = false
        txtView.isScrollEnabled = false
        txtView.textAlignment = .center
        txtView.textColor = UIColor.white.withAlphaComponent(0.88)
        txtView.font = .preferredFont(forTextStyle: .body)
        txtView.adjustsFontForContentSizeCategory = true
        txtView.textContainerInset = UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18)
        lyricsCard.contentView.addSubview(txtView)

        NSLayoutConstraint.activate([
            lyricsCard.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            lyricsCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 108),
            txtView.leadingAnchor.constraint(equalTo: lyricsCard.contentView.leadingAnchor),
            txtView.trailingAnchor.constraint(equalTo: lyricsCard.contentView.trailingAnchor),
            txtView.topAnchor.constraint(equalTo: lyricsCard.contentView.topAnchor),
            txtView.bottomAnchor.constraint(equalTo: lyricsCard.contentView.bottomAnchor),
        ])
    }

    private func configureAccessibility() {
        playButton.accessibilityLabel = L10n.play
        playButton.accessibilityHint = L10n.playPauseHint
        prevButton.accessibilityLabel = L10n.previousTrack
        nextButton.accessibilityLabel = L10n.nextTrack
        downloadButton.accessibilityLabel = L10n.download
        likeButton.accessibilityLabel = L10n.like
        timelineSlider.accessibilityLabel = L10n.playbackPosition
        timelineSlider.accessibilityHint = L10n.playbackPositionHint
        txtView.accessibilityLabel = L10n.lyrics
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
                guard let self else { return }
                let placeholder = Asset.image(named: "placeholder")
                let options: KingfisherOptionsInfo = [.transition(.fade(0.28)), .cacheOriginalImage]
                imgView.kf.setImage(with: url, placeholder: placeholder, options: options)
                bgImageView.kf.setImage(with: url, placeholder: placeholder, options: options)
            })
            .disposed(by: disposeBag)

        viewModel.isPlaying
            .drive(onNext: { [weak self] isPlaying in
                self?.updatePlaybackAppearance(isPlaying: isPlaying)
            })
            .disposed(by: disposeBag)

        viewModel.isLiked
            .drive(onNext: { [weak self] isLiked in
                self?.updateLikeAppearance(isLiked: isLiked)
            })
            .disposed(by: disposeBag)

        viewModel.downloadState
            .drive(onNext: { [weak self] state in
                self?.updateDownloadAppearance(state: state)
            })
            .disposed(by: disposeBag)

        viewModel.songProgress
            .drive(onNext: { [weak self] progress in
                guard let self, !isSeeking else { return }
                timelineSlider.value = progress
                updateTimelineAccessibility()
            })
            .disposed(by: disposeBag)

        viewModel.durationSeconds
            .drive(onNext: { [weak self] duration in
                self?.latestDuration = duration
                self?.updateTimelineAccessibility()
            })
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
            .drive(onNext: { [weak self] isLoading in
                self?.updateLoadingAppearance(isLoading: isLoading)
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
    }

    private func bindControls() {
        playButton.rx.tap
            .do(onNext: { ExperienceFeedback.transport() })
            .bind(to: viewModel.playPauseButtonTapped)
            .disposed(by: disposeBag)

        nextButton.rx.tap
            .do(onNext: { ExperienceFeedback.transport() })
            .bind(to: viewModel.nextButtonTapped)
            .disposed(by: disposeBag)

        prevButton.rx.tap
            .do(onNext: { ExperienceFeedback.transport() })
            .bind(to: viewModel.previousButtonTapped)
            .disposed(by: disposeBag)

        likeButton.rx.tap
            .do(onNext: { ExperienceFeedback.selection() })
            .bind(to: viewModel.likeButtonTapped)
            .disposed(by: disposeBag)

        downloadButton.rx.tap
            .do(onNext: { ExperienceFeedback.selection() })
            .bind(to: viewModel.downloadButtonTapped)
            .disposed(by: disposeBag)

        timelineSlider.addTarget(self, action: #selector(seekStarted), for: .touchDown)
        timelineSlider.addTarget(self, action: #selector(seekChanged), for: .valueChanged)
        timelineSlider.addTarget(
            self,
            action: #selector(seekFinished),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
    }

    private func updatePlaybackAppearance(isPlaying: Bool) {
        var configuration = playButton.configuration
        configuration?.image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
        playButton.configuration = configuration
        playButton.accessibilityLabel = isPlaying ? L10n.pause : L10n.play
        imgView.setPlaybackActive(isPlaying)
    }

    private func updateLoadingAppearance(isLoading: Bool) {
        playButton.isEnabled = !isLoading
        prevButton.isEnabled = !isLoading
        nextButton.isEnabled = !isLoading
        if isLoading {
            playerActivityIndicator.startAnimating()
            var configuration = playButton.configuration
            configuration?.image = nil
            playButton.configuration = configuration
            playButton.accessibilityValue = L10n.loading
        } else {
            playerActivityIndicator.stopAnimating()
            playButton.accessibilityValue = nil
            updatePlaybackAppearance(isPlaying: viewModelIsPlaying)
        }
    }

    private var viewModelIsPlaying: Bool {
        AudioManager.shared.playbackState.value == .playing
    }

    private func updateLikeAppearance(isLiked: Bool) {
        var configuration = likeButton.configuration
        configuration?.title = isLiked ? L10n.liked : L10n.like
        configuration?.image = UIImage(systemName: isLiked ? "heart.fill" : "heart")
        configuration?.baseForegroundColor = isLiked ? ExperienceTheme.favorite : UIColor.white.withAlphaComponent(0.86)
        likeButton.configuration = configuration
        likeButton.accessibilityValue = isLiked ? L10n.selected : L10n.notSelected
    }

    private func updateDownloadAppearance(state: PlayerDownloadState) {
        var configuration = downloadButton.configuration
        switch state {
        case .available:
            configuration?.title = L10n.download
            configuration?.image = UIImage(systemName: "arrow.down.circle")
            downloadButton.isEnabled = true
            downloadButton.accessibilityValue = L10n.available
        case .waiting:
            configuration?.title = L10n.downloadWaiting
            configuration?.image = UIImage(systemName: "clock")
            downloadButton.isEnabled = false
            downloadButton.accessibilityValue = L10n.downloadWaiting
        case .downloading(let percentage):
            configuration?.title = "\(percentage)%"
            configuration?.image = UIImage(systemName: "arrow.down.circle")
            downloadButton.isEnabled = false
            downloadButton.accessibilityValue = String(
                format: L10n.downloadProgressFormat,
                L10n.downloadInProgress,
                percentage
            )
        case .paused:
            configuration?.title = L10n.resume
            configuration?.image = UIImage(systemName: "arrow.clockwise.circle")
            downloadButton.isEnabled = true
            downloadButton.accessibilityValue = L10n.downloadPaused
        case .completed:
            configuration?.title = L10n.downloaded
            configuration?.image = UIImage(systemName: "checkmark.circle.fill")
            downloadButton.isEnabled = false
            downloadButton.accessibilityValue = L10n.downloadCompleted
            if previousDownloadState != nil, previousDownloadState != .completed {
                ExperienceFeedback.success()
                UIAccessibility.post(notification: .announcement, argument: L10n.downloadCompletedAnnouncement)
            }
        case .failed:
            configuration?.title = L10n.retry
            configuration?.image = UIImage(systemName: "exclamationmark.circle")
            downloadButton.isEnabled = true
            downloadButton.accessibilityValue = L10n.downloadFailed
        }
        configuration?.baseForegroundColor = state == .completed
            ? .systemGreen
            : UIColor.white.withAlphaComponent(0.86)
        downloadButton.configuration = configuration
        previousDownloadState = state
    }

    private func updateTimelineAccessibility() {
        let elapsed = latestDuration * Double(timelineSlider.value)
        timelineSlider.accessibilityValue = "\(Common.getMinuteDisplay(seconds: Int(elapsed))) / \(Common.getMinuteDisplay(seconds: Int(latestDuration)))"
    }

    @objc private func seekStarted() {
        isSeeking = true
        ExperienceFeedback.selection()
    }

    @objc private func seekChanged() {
        let target = latestDuration * Double(timelineSlider.value)
        songTimePlayLabel.text = Common.getMinuteDisplay(seconds: Int(target))
        updateTimelineAccessibility()
    }

    @objc private func seekFinished() {
        isSeeking = false
        viewModel.seekRequested.accept(timelineSlider.value)
        ExperienceFeedback.selection()
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
