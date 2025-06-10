//
//  BaseViewController.swift
//  BaiduFM
//
//  现代化基础视图控制器 - 提供统一的UI状态管理和响应式绑定
//  包含加载状态、错误处理、空状态显示等通用功能
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - UI状态枚举
enum ViewState {
    case loading    // 加载中
    case content    // 显示内容
    case empty      // 空状态
    case error      // 错误状态
}

// MARK: - 基础视图控制器
class BaseViewController: UIViewController {
    
    // MARK: - 响应式属性
    let disposeBag = DisposeBag()
    let viewState = BehaviorRelay<ViewState>(value: .loading)
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = BehaviorRelay<String?>(value: nil)
    
    // MARK: - UI组件
    private lazy var loadingView: LoadingView = {
        let view = LoadingView()
        view.isHidden = true
        return view
    }()
    
    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.isHidden = true
        return view
    }()
    
    private lazy var errorView: ErrorView = {
        let view = ErrorView()
        view.isHidden = true
        return view
    }()
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 设置导航栏样式
        setupNavigationBarStyle()
    }
    
    // MARK: - UI设置
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // 添加状态视图
        view.addSubview(loadingView)
        view.addSubview(emptyStateView)
        view.addSubview(errorView)
    }
    
    private func setupConstraints() {
        // 加载视图约束
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        // 空状态视图约束
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
        
        // 错误视图约束
        errorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(40)
        }
    }
    
    private func setupBindings() {
        // 监听视图状态变化
        viewState
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] state in
                self?.updateViewForState(state)
            })
            .disposed(by: disposeBag)
        
        // 监听加载状态
        isLoading
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] loading in
                if loading {
                    self?.viewState.accept(.loading)
                }
            })
            .disposed(by: disposeBag)
        
        // 监听错误消息
        errorMessage
            .filter { $0 != nil }
            .subscribe(onNext: { [weak self] message in
                self?.viewState.accept(.error)
                self?.errorView.configure(message: message ?? "未知错误")
            })
            .disposed(by: disposeBag)
        
        // 错误视图重试按钮点击
        errorView.retryTapped
            .subscribe(onNext: { [weak self] in
                self?.onRetryTapped()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - 状态更新
    private func updateViewForState(_ state: ViewState) {
        DispatchQueue.main.async { [weak self] in
            self?.loadingView.isHidden = (state != .loading)
            self?.emptyStateView.isHidden = (state != .empty)
            self?.errorView.isHidden = (state != .error)
            
            // 更新加载视图动画
            if state == .loading {
                self?.loadingView.startAnimating()
            } else {
                self?.loadingView.stopAnimating()
            }
        }
    }
    
    // MARK: - 导航栏样式配置
    private func setupNavigationBarStyle() {
        guard let navigationController = navigationController else { return }
        
        // 设置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.tintColor = UIColor.systemBlue
    }
    
    // MARK: - 公共方法
    
    /// 显示加载状态
    func showLoading() {
        viewState.accept(.loading)
    }
    
    /// 显示内容
    func showContent() {
        viewState.accept(.content)
    }
    
    /// 显示空状态
    func showEmpty(message: String = "暂无数据", icon: String = "music.note.list") {
        emptyStateView.configure(message: message, icon: icon)
        viewState.accept(.empty)
    }
    
    /// 显示错误状态
    func showError(message: String) {
        errorMessage.accept(message)
    }
    
    /// 显示成功提示
    func showSuccess(message: String) {
        showToast(message: message, type: .success)
    }
    
    /// 显示警告提示
    func showWarning(message: String) {
        showToast(message: message, type: .warning)
    }
    
    /// 显示Toast提示
    private func showToast(message: String, type: ToastType) {
        let toast = ToastView(message: message, type: type)
        view.addSubview(toast)
        
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.left.greaterThanOrEqualToSuperview().offset(20)
            make.right.lessThanOrEqualToSuperview().offset(-20)
        }
        
        toast.show()
    }
    
    // MARK: - 可重写方法
    
    /// 重试按钮点击事件 - 子类可重写
    @objc open func onRetryTapped() {
        // 子类实现具体的重试逻辑
    }
    
    /// 空状态视图点击事件 - 子类可重写
    @objc open func onEmptyStateTapped() {
        // 子类实现具体的处理逻辑
    }
}

// MARK: - 加载视图
class LoadingView: UIView {
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        
        addSubview(activityIndicator)
        addSubview(messageLabel)
        
        activityIndicator.color = UIColor.systemBlue
        
        messageLabel.text = "加载中..."
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = UIColor.secondaryLabel
        messageLabel.textAlignment = .center
        
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        messageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(activityIndicator.snp.bottom).offset(10)
            make.bottom.equalToSuperview()
        }
    }
    
    func startAnimating() {
        activityIndicator.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicator.stopAnimating()
    }
}

// MARK: - 空状态视图
class EmptyStateView: UIView {
    
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    
    let actionTapped = PublishSubject<Void>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        
        addSubview(iconImageView)
        addSubview(messageLabel)
        addSubview(actionButton)
        
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.secondaryLabel
        
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor.secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        actionButton.setTitle("刷新", for: .normal)
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        actionButton.backgroundColor = UIColor.systemBlue
        actionButton.setTitleColor(UIColor.white, for: .normal)
        actionButton.layer.cornerRadius = 22
        actionButton.isHidden = true
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
        }
        
        actionButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(messageLabel.snp.bottom).offset(20)
            make.width.equalTo(120)
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }
    
    func configure(message: String, icon: String = "music.note.list", showAction: Bool = false) {
        messageLabel.text = message
        iconImageView.image = UIImage(systemName: icon)
        actionButton.isHidden = !showAction
    }
    
    @objc private func actionButtonTapped() {
        actionTapped.onNext(())
    }
}

// MARK: - 错误视图
class ErrorView: UIView {
    
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    
    let retryTapped = PublishSubject<Void>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.clear
        
        addSubview(iconImageView)
        addSubview(messageLabel)
        addSubview(retryButton)
        
        iconImageView.image = UIImage(systemName: "exclamationmark.triangle")
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = UIColor.systemOrange
        
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.textColor = UIColor.secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        retryButton.setTitle("重试", for: .normal)
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        retryButton.backgroundColor = UIColor.systemBlue
        retryButton.setTitleColor(UIColor.white, for: .normal)
        retryButton.layer.cornerRadius = 22
        
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(60)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
            make.left.right.equalToSuperview()
        }
        
        retryButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(messageLabel.snp.bottom).offset(20)
            make.width.equalTo(120)
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
    }
    
    func configure(message: String) {
        messageLabel.text = message
    }
    
    @objc private func retryButtonTapped() {
        retryTapped.onNext(())
    }
}

// MARK: - Toast视图
enum ToastType {
    case success
    case warning
    case error
    
    var color: UIColor {
        switch self {
        case .success: return UIColor.systemGreen
        case .warning: return UIColor.systemOrange
        case .error: return UIColor.systemRed
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        }
    }
}

class ToastView: UIView {
    
    private let messageLabel = UILabel()
    private let iconImageView = UIImageView()
    
    init(message: String, type: ToastType) {
        super.init(frame: .zero)
        setupUI(message: message, type: type)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(message: String, type: ToastType) {
        backgroundColor = type.color.withAlphaComponent(0.9)
        layer.cornerRadius = 22
        
        addSubview(iconImageView)
        addSubview(messageLabel)
        
        iconImageView.image = UIImage(systemName: type.icon)
        iconImageView.tintColor = UIColor.white
        
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        messageLabel.textColor = UIColor.white
        messageLabel.numberOfLines = 0
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.top.bottom.equalToSuperview().inset(12)
        }
    }
    
    func show() {
        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 20)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 1
            self.transform = .identity
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hide()
            }
        }
    }
    
    private func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: -20)
        }) { _ in
            self.removeFromSuperview()
        }
    }
} 