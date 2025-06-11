import UIKit
import RxSwift
import RxCocoa
import LTMorphingLabel

class ViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var nameLabel: LTMorphingLabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var imgView: RoundImageView!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var songTimeLengthLabel: UILabel!
    @IBOutlet weak var songTimePlayLabel: UILabel!
    
    // MARK: - Constants
    private enum Constants {
        static let playButtonImageName = "player_btn_play_normal"
        static let pauseButtonImageName = "player_btn_pause_normal"
    }
    
    // MARK: - Properties
    private let viewModel = PlayerViewModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        nameLabel.morphingEffect = .fall
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgImageView.addSubview(blurView)
        // Drive the navigation bar title
        viewModel.channelName.drive(navigationItem.rx.title).disposed(by: disposeBag)
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // ViewModel -> UI (Outputs)
        viewModel.songName
            .drive(nameLabel.rx.text)
            .disposed(by: disposeBag)
            
        viewModel.artistName
            .drive(artistLabel.rx.text)
            .disposed(by: disposeBag)
            
        viewModel.albumName
            .drive(albumLabel.rx.text)
            .disposed(by: disposeBag)
            
        viewModel.albumImage
            .drive(onNext: { [weak self] image in
                self?.imgView.image = image
            })
            .disposed(by: disposeBag)
            
        viewModel.backgroundImage
            .drive(bgImageView.rx.image)
            .disposed(by: disposeBag)
            
        viewModel.isPlaying
            .drive(onNext: { [weak self] isPlaying in
                let imageName = isPlaying ? Constants.pauseButtonImageName : Constants.playButtonImageName
                self?.playButton.setImage(UIImage(named: imageName), for: .normal)
                isPlaying ? self?.imgView.rotation() : self?.imgView.layer.removeAllAnimations()
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
        
        // UI -> ViewModel (Inputs)
        playButton.rx.tap
            .bind(to: viewModel.playPauseButtonTapped)
            .disposed(by: disposeBag)
            
        nextButton.rx.tap
            .bind(to: viewModel.nextButtonTapped)
            .disposed(by: disposeBag)
            
        prevButton.rx.tap
            .bind(to: viewModel.prevButtonTapped)
            .disposed(by: disposeBag)
            
        likeButton.rx.tap
            .bind(to: viewModel.likeButtonTapped)
            .disposed(by: disposeBag)
            
        downloadButton.rx.tap
            .bind(to: viewModel.downloadButtonTapped)
            .disposed(by: disposeBag)
    }
} 