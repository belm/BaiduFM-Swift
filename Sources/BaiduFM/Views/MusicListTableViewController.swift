#if canImport(UIKit)
//
//  MusicListTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/13.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

// MARK: - 音乐列表视图控制器
class MusicListTableViewController: UITableViewController {
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private var songs: [SongInfo] = []
    private var isLoading = false
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindData()
        loadInitialData()
    }
    
    // MARK: - 私有方法
    
    /// 设置UI
    private func setupUI() {
        title = L10n.songList
        
        // 设置下拉刷新
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        // 设置表格属性
        tableView.rowHeight = 60
        tableView.estimatedRowHeight = UITableView.automaticDimension
    }
    
    /// 绑定数据
    private func bindData() {
        // 监听歌曲信息列表变化
        DataCenter.shared.currentSongInfoList
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] songInfoList in
                self?.songs = songInfoList
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
                self?.isLoading = false
            })
            .disposed(by: disposeBag)
        
        // 监听当前频道变化
        DataCenter.shared.currentChannel
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] channel in
                let channelName = channel?.name ?? ""
                self?.title = channelName.isEmpty ? L10n.songList : channelName
            })
            .disposed(by: disposeBag)
    }
    
    /// 加载初始数据
    private func loadInitialData() {
        guard !isLoading else { return }
        
        let currentChannel = DataCenter.shared.currentChannel.value
        guard currentChannel != nil else {
            showErrorAlert(message: L10n.chooseChannel)
            return
        }
        
        isLoading = true
        refreshControl?.beginRefreshing()
        
        // 加载歌曲列表
        DataCenter.shared.loadSongList()
            .flatMap { _ in
                // 然后加载歌曲详情
                return DataCenter.shared.loadSongDetails()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    print("歌曲列表加载成功")
                },
                onError: { [weak self] error in
                    print("歌曲列表加载失败: \(error.localizedDescription)")
                    self?.refreshControl?.endRefreshing()
                    self?.isLoading = false
                    self?.showErrorAlert(message: L10n.loadSongsFailed)
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 加载更多歌曲
    private func loadMoreSongs() {
        guard !isLoading else { return }
        
        isLoading = true
        
        DataCenter.shared.loadMoreSongs()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    print("加载更多歌曲成功")
                },
                onError: { [weak self] error in
                    print("加载更多歌曲失败: \(error.localizedDescription)")
                    self?.isLoading = false
                    self?.showErrorAlert(message: L10n.loadMoreSongsFailed)
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 处理下拉刷新
    @objc private func handleRefresh() {
        // 重置显示范围并重新加载
        DataCenter.shared.currentStartIndex.accept(0)
        DataCenter.shared.currentEndIndex.accept(20) // 直接使用默认页面大小
        loadInitialData()
    }
    
    /// 显示错误提示
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: L10n.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.ok, style: .default))
        present(alert, animated: true)
    }

    // MARK: - 内存管理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("收到内存警告 - MusicListTableViewController")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let songInfo = songs[indexPath.row]
        
        // 配置单元格
        cell.textLabel?.text = songInfo.name
        cell.detailTextLabel?.text = songInfo.artistName
        
        // 使用Kingfisher加载图片
        if let imageView = cell.imageView,
           let url = URL(string: songInfo.picUrl) {
            imageView.kf.setImage(
                with: url,
                placeholder: Asset.image(named: "placeholder"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 播放选中的歌曲
        DataCenter.shared.playSong(at: indexPath.row)
        
        // 发送通知
        NotificationCenter.default.post(
            name: .channelMusicListClick,
            object: nil
        )
        
        // 返回上一页
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 添加动画效果
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animate(withDuration: 0.25) {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        }
        
        // 检查是否需要加载更多
        if indexPath.row == songs.count - 3 { // 提前3行开始加载
            loadMoreSongs()
        }
    }
}

#endif
