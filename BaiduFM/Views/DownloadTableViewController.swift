//
//  DownloadTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

// MARK: - 下载歌曲列表视图控制器
class DownloadTableViewController: UITableViewController {
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private var downloadedSongs: [Song] = []
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadDownloadedSongs()
    }
    
    // MARK: - 私有方法
    
    /// 设置UI
    private func setupUI() {
        title = "已下载"
        
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
            action: #selector(clearAllDownloads)
        )
        navigationItem.rightBarButtonItem = clearButton
    }
    
    /// 加载下载的歌曲
    private func loadDownloadedSongs() {
        // 从数据库获取下载的歌曲
        downloadedSongs = DataCenter.shared.dbSongList.getAllDownload() ?? []
        
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }
    }
    
    /// 更新空状态显示
    private func updateEmptyState() {
        if downloadedSongs.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
        }
    }
    
    /// 显示空状态
    private func showEmptyState() {
        let emptyLabel = UILabel()
        emptyLabel.text = "暂无下载的歌曲"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .gray
        emptyLabel.font = UIFont.systemFont(ofSize: 16)
        tableView.backgroundView = emptyLabel
    }
    
    /// 隐藏空状态
    private func hideEmptyState() {
        tableView.backgroundView = nil
    }
    
    /// 清空所有下载
    @objc private func clearAllDownloads() {
        let alert = UIAlertController(
            title: "确认清空",
            message: "确定要清空所有下载的歌曲吗？此操作不可恢复。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            self?.performClearAllDownloads()
        })
        
        present(alert, animated: true)
    }
    
    /// 执行清空操作
    private func performClearAllDownloads() {
        // 清理文件系统中的下载文件
        Common.cleanAllDownloadSong()
        
        // 清理数据库
        DataCenter.shared.dbSongList.cleanDownloadList()
        
        // 重新加载数据
        loadDownloadedSongs()
        
        // 显示成功提示
        let alert = UIAlertController(
            title: "清空完成",
            message: "所有下载的歌曲已清空",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 内存管理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("收到内存警告 - DownloadTableViewController")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return downloadedSongs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let song = downloadedSongs[indexPath.row]
        
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
        
        // 添加下载完成的标识
        cell.accessoryType = .checkmark
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let song = downloadedSongs[indexPath.row]
        let songData: [String: Any] = ["song": song]
        
        // 发送通知播放下载的歌曲
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
    
    // MARK: - 滑动删除支持
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let song = downloadedSongs[indexPath.row]
            
            // 从数组中移除
            downloadedSongs.remove(at: indexPath.row)
            
            // 从数据库中删除
            DataCenter.shared.dbSongList.deleteSong(songId: song.sid)
            
            // 删除本地文件
            Common.deleteDownloadedSong(song: song)
            
            // 更新UI
            tableView.deleteRows(at: [indexPath], with: .fade)
            updateEmptyState()
        }
    }
}
