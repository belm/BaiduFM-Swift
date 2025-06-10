//
//  ChannelTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/13.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - 频道列表视图控制器
class ChannelTableViewController: UITableViewController {
    
    // MARK: - 私有属性
    private let disposeBag = DisposeBag()
    private var channels: [Channel] = []
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindData()
        loadChannels()
    }
    
    // MARK: - 私有方法
    
    /// 设置UI
    private func setupUI() {
        title = "频道列表"
        
        // 设置下拉刷新
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }
    
    /// 绑定数据
    private func bindData() {
        // 监听频道列表数据变化
        DataCenter.shared.channelListInfo
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] channels in
                self?.channels = channels
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
            })
            .disposed(by: disposeBag)
    }
    
    /// 加载频道列表
    private func loadChannels() {
        // 如果已有数据，直接使用
        if !DataCenter.shared.channelListInfo.value.isEmpty {
            return
        }
        
        // 显示加载指示器
        refreshControl?.beginRefreshing()
        
        // 加载频道数据
        DataCenter.shared.loadChannelList()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    // 数据加载成功，UI会通过绑定自动更新
                    print("频道列表加载成功")
                },
                onError: { [weak self] error in
                    print("频道列表加载失败: \(error.localizedDescription)")
                    self?.refreshControl?.endRefreshing()
                    
                    // 显示错误提示
                    self?.showErrorAlert(message: "加载频道列表失败，请检查网络连接")
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// 处理下拉刷新
    @objc private func handleRefresh() {
        loadChannels()
    }
    
    /// 显示错误提示
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - 内存管理
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("收到内存警告 - ChannelTableViewController")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        // 配置单元格
        let channel = channels[indexPath.row]
        cell.textLabel?.text = channel.name
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let channel = channels[indexPath.row]
        
        // 使用DataCenter更新当前频道
        DataCenter.shared.currentChannel.accept(channel.id)
        DataCenter.shared.currentChannelName.accept(channel.name)
        
        // 保存用户选择
        UserDefaults.standard.set(channel.id, forKey: "LAST_PLAY_CHANNEL_ID")
        UserDefaults.standard.set(channel.name, forKey: "LAST_PLAY_CHANNEL_NAME")
        
        // 发送通知表示频道已选择
        NotificationCenter.default.post(name: Notification.Name("ChannelSelected"), object: channel)
        
        // 返回上一页
        navigationController?.popViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 添加动画效果
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animate(withDuration: 0.25) {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        }
    }
}
