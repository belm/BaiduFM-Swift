#if canImport(UIKit)
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

// MARK: - Channel List View Controller
class ChannelTableViewController: UITableViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let dataCenter = DataCenter.shared
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupBindings()
        loadChannels()
    }
    
    // MARK: - Private Methods
    
    /// Setup the basic UI elements
    private func setupUI() {
        title = L10n.channels
        ExperienceTheme.styleList(tableView)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.dataSource = nil
    }
    
    /// Bind ViewModel data to UI
    private func setupBindings() {
        // Bind channel list data directly to the table view
        dataCenter.channelListInfo
            .asDriver()
            .drive(tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { [weak self] _, channel, cell in
                ExperienceTheme.styleListCell(cell)
                cell.textLabel?.text = channel.name
                let isCurrentChannel = channel.id == self?.dataCenter.currentChannel.value?.id
                cell.accessoryType = isCurrentChannel ? .checkmark : .none
                cell.accessibilityTraits = isCurrentChannel ? [.button, .selected] : .button
            }
            .disposed(by: disposeBag)
        
        // Handle row selection
        tableView.rx.modelSelected(Channel.self)
            .subscribe(onNext: { [weak self] channel in
                ExperienceFeedback.selection()
                self?.dataCenter.currentChannel.accept(channel)
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
            
        // End refreshing when data loads
        dataCenter.channelListInfo
            .map { _ in false }
            .asDriver(onErrorJustReturn: false)
            .drive(refreshControl!.rx.isRefreshing)
            .disposed(by: disposeBag)
    }
    
    /// Load channel list from DataCenter
    private func loadChannels() {
        // If data already exists, don't reload unless refreshing
        if !dataCenter.channelListInfo.value.isEmpty {
            return
        }
        
        refreshControl?.beginRefreshing()
        
        dataCenter.loadChannelList()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onError: { [weak self] error in
                    print("Failed to load channels: \(error.localizedDescription)")
                    self?.showErrorAlert(message: L10n.loadChannelsFailed)
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// Handle pull-to-refresh action
    @objc private func handleRefresh() {
        // Always reload channels on refresh
        dataCenter.loadChannelList()
            .subscribe(
                onError: { [weak self] error in
                    print("Failed to refresh channels: \(error.localizedDescription)")
                    self?.showErrorAlert(message: L10n.refreshChannelsFailed)
                }
            )
            .disposed(by: disposeBag)
    }
    
    /// Show an error alert
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: L10n.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.ok, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory warning received - ChannelTableViewController")
    }

    // MARK: - Table view data source (Now managed by Rx)
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ExperienceMotion.reveal(cell: cell)
    }
}

#endif
