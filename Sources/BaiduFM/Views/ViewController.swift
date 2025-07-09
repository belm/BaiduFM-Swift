import UIKit

// 主控制器类 - 音乐播放界面
class ViewController: UIViewController {

    // MARK: - Outlets - UI组件连接
    @IBOutlet weak var nameLabel: UILabel!
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
    
    // MARK: - Constants - 常量定义
    private enum Constants {
        static let playButtonImageName = "player_btn_play_normal"
        static let pauseButtonImageName = "player_btn_pause_normal"
    }
    
    // MARK: - Properties - 属性
    private let viewModel = PlayerViewModel()
    private var progressTimer: Timer?
    
    // MARK: - Lifecycle - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupNotifications()
        viewModel.initialize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        progressTimer?.invalidate()
    }
    
    // MARK: - UI Setup - UI设置
    private func setupUI() {
        // 设置背景模糊效果
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        bgImageView.addSubview(blurView)
        
        // 初始化UI状态
        updatePlayButton(isPlaying: false)
    }
    
    // MARK: - Actions Setup - 设置按钮动作
    private func setupActions() {
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        prevButton.addTarget(self, action: #selector(prevButtonTapped), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(downloadButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Notifications Setup - 设置通知监听
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(songDidChange),
            name: .audioManagerSongDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playbackStateDidChange),
            name: .audioManagerPlaybackStateDidChange,
            object: nil
        )
        
        // 启动进度更新定时器
        startProgressTimer()
    }
    
    // MARK: - Timer Methods - 定时器方法
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        let audioManager = AudioManager.shared
        let progress = audioManager.currentProgress
        let currentTime = audioManager.currentTime
        let totalTime = audioManager.totalTime
        
        DispatchQueue.main.async { [weak self] in
            self?.progressView.progress = Float(progress)
            self?.songTimePlayLabel.text = self?.formatTime(currentTime)
            self?.songTimeLengthLabel.text = self?.formatTime(totalTime)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Button Actions - 按钮响应方法
    @objc private func playButtonTapped() {
        viewModel.togglePlayPause()
    }
    
    @objc private func nextButtonTapped() {
        viewModel.playNext()
    }
    
    @objc private func prevButtonTapped() {
        viewModel.playPrevious()
    }
    
    @objc private func likeButtonTapped() {
        viewModel.toggleLike()
    }
    
    @objc private func downloadButtonTapped() {
        viewModel.downloadCurrentSong()
    }
    
    // MARK: - Notification Handlers - 通知处理方法
    @objc private func songDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updateSongInfo()
        }
    }
    
    @objc private func playbackStateDidChange() {
        DispatchQueue.main.async { [weak self] in
            self?.updatePlaybackState()
        }
    }
    
    // MARK: - UI Update Methods - UI更新方法
    private func updateSongInfo() {
        guard let currentSong = viewModel.currentSong else {
            clearSongInfo()
            return
        }
        
        // 更新歌曲信息
        updateLabelWithAnimation(nameLabel, text: currentSong.title)
        artistLabel.text = currentSong.artist
        albumLabel.text = currentSong.albumtitle
        
        // 更新专辑图片
        updateAlbumImage(with: currentSong.pic)
        
        // 更新频道名称
        navigationItem.title = viewModel.currentChannelName
        
        // 更新歌词
        updateLyrics()
    }
    
    private func updateLabelWithAnimation(_ label: UILabel, text: String?) {
        UIView.transition(with: label,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            label.text = text
        }, completion: nil)
    }
    
    private func updateAlbumImage(with urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            imgView.image = UIImage(named: "placeholder")
            bgImageView.image = UIImage(named: "placeholder")
            return
        }
        
        // 使用原生方法加载图片
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.imgView.image = image
                self?.bgImageView.image = image
            }
        }.resume()
    }
    
    private func updatePlaybackState() {
        let audioManager = AudioManager.shared
        let isPlaying = audioManager.isPlaying
        
        updatePlayButton(isPlaying: isPlaying)
        
        // 更新专辑图片旋转动画
        if isPlaying {
            imgView.rotation()
        } else {
            imgView.layer.removeAllAnimations()
        }
    }
    
    private func updatePlayButton(isPlaying: Bool) {
        let imageName = isPlaying ? Constants.pauseButtonImageName : Constants.playButtonImageName
        playButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    private func clearSongInfo() {
        nameLabel.text = "暂无歌曲"
        artistLabel.text = ""
        albumLabel.text = ""
        imgView.image = UIImage(named: "placeholder")
        bgImageView.image = UIImage(named: "placeholder")
        txtView.text = "暂无歌词"
    }
    
    private func updateLyrics() {
        let audioManager = AudioManager.shared
        let currentTime = audioManager.currentTime
        let currentLyrics = viewModel.getCurrentLyrics(currentTime: currentTime)
        
        DispatchQueue.main.async { [weak self] in
            self?.txtView.text = currentLyrics
        }
    }
}

// MARK: - Notification Names Extension - 通知名称扩展
extension Notification.Name {
    static let audioManagerSongDidChange = Notification.Name("AudioManagerSongDidChange")
    static let audioManagerPlaybackStateDidChange = Notification.Name("AudioManagerPlaybackStateDidChange")
} 