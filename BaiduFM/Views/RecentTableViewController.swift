//
//  RecentTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

// MARK: - 最近播放列表视图控制器
class RecentTableViewController: UITableViewController {
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private var recentSongs: [Song] = []

    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadRecentSongs()
    }
    
    // MARK: - 私有方法
    
    /// 设置UI
    private func setupUI() {
        title = "最近播放"
        
        // 设置表格属性
        tableView.rowHeight = 60
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
        // 设置空状态
        tableView.tableFooterView = UIView()
    }
    
    /// 设置导航栏
    private func setupNavigationBar() {
        // 添加清空按钮
        let clearButton = UIBarButtonItem(
            title: "清空",
            style: .plain,
            target: self,
            action: #selector(clearAllRecent)
        )
        navigationItem.rightBarButtonItem = clearButton
    }
    
    /// 加载最近播放的歌曲
    private func loadRecentSongs() {
        // 从数据库获取最近播放的歌曲
        recentSongs = DataCenter.shared.dbSongList.getAllRecent() ?? []
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }
    }
    
    /// 更新空状态显示
    private func updateEmptyState() {
        if recentSongs.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }
    
    /// 显示空状态
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无播放记录\n开始播放音乐后这里会显示最近播放的歌曲"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .gray
        emptyLabel.font = UIFont.systemFont(ofSize: 16)
        emptyLabel.numberOfLines = 0
        tableView.backgroundView = emptyLabel
    }
    
    /// 隐藏空状态
    private func hideEmptyState() {
        tableView.backgroundView = nil
    }
    
    /// 清空所有最近播放
    @objc private func clearAllRecent() {
        let alert = UIAlertController(
            title: "确认清空",
            message: "确定要清空所有播放记录吗？此操作不可恢复。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.performClearAllRecent()
        })
        
        present(alert, animated: true)
    }
    
    /// 执行清空操作
    private func performClearAllRecent() {
        // 清理数据库
        DataCenter.shared.dbSongList.clearRecentList()
        
        // 重新加载数据
        loadRecentSongs()
        
        // 显示成功提示
        let alert = UIAlertController(
            title: "清空完成",
            message: "所有播放记录已清空",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 内存管理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("收到内存警告 - RecentTableViewController")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recentSongs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let song = recentSongs[indexPath.row]
        
        // 配置单元格
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        
        // 使用Kingfisher加载图片
        if let imageView = cell.imageView,
           let url = URL(string: song.pic_url) {
            imageView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "placeholder"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        }
        
        // 添加播放次数或时间标识
        cell.accessoryType = .detailButton
        
        return cell
    }

    // MARK: - 滑动删除支持
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let song = recentSongs[indexPath.row]
            
            // 从数组中移除
            recentSongs.remove(at: indexPath.row)
            
            // 从数据库中删除
            DataCenter.shared.dbSongList.deleteRecentSong(songId: song.sid)
            
            // 更新UI
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateEmptyState()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let song = recentSongs[indexPath.row]
        let songData: [String: Any] = ["song": song]
        
        // 发送通知播放最近播放的歌曲
        NotificationCenter.default.post(
            name: Notification.Name("OTHER_MUSIC_LIST_CLICK_NOTIFICATION"),
            object: nil,
            userInfo: songData
        )
        
        // 切换到播放页面
        tabBarController?.selectedIndex = 0
        if let mainNav = tabBarController?.viewControllers?[0] as? UINavigationController {
            mainNav.popToRootViewController(animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 添加动画效果
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animate(withDuration: 0.25) {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        // 可以在这里添加详情页面或更多操作
        let song = recentSongs[indexPath.row]
        
        let alert = UIAlertController(
            title: song.name,
            message: "艺术家: \(song.artist)\n专辑: \(song.album)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
