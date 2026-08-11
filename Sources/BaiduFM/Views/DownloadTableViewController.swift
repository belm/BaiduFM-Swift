#if canImport(UIKit)
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

// MARK: - Downloaded Songs View Controller
class DownloadTableViewController: UITableViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let dataCenter = DataCenter.shared
    private let downloadManager = DownloadManager.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataCenter.loadDownloadedSongs()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = L10n.downloads
        ExperienceTheme.styleList(tableView)
        tableView.dataSource = nil
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(title: L10n.clearAll, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        downloadManager.downloadTasks
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { [weak self] _, task, cell in
                self?.configure(cell: cell, with: task)
            }
            .disposed(by: disposeBag)

        downloadManager.downloadTasks
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] hasSongs in
                self?.tableView.backgroundView = hasSongs ? nil : self?.createEmptyStateView()
            })
            .disposed(by: disposeBag)
            
        tableView.rx.modelSelected(SongDownloadTask.self)
            .subscribe(onNext: { [weak self] task in
                guard let self else { return }
                ExperienceFeedback.selection()
                switch task.status.value {
                case .completed:
                    dataCenter.playSong(song: task.song)
                    tabBarController?.selectedIndex = 0
                case .paused, .failed, .cancelled:
                    downloadManager.resumeDownload(taskId: task.id)
                case .waiting, .downloading:
                    break
                }
            })
            .disposed(by: disposeBag)

        downloadManager.downloadTasks
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)
            .drive(navigationItem.rightBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)

        tableView.rx.modelDeleted(SongDownloadTask.self)
            .subscribe(onNext: { [weak self, downloadManager] task in
                guard let self else { return }
                downloadManager.deleteDownload(taskId: task.id)
                    .subscribe(onError: { error in
                        print("Failed to remove download: \(error.localizedDescription)")
                    })
                    .disposed(by: self.disposeBag)
            })
            .disposed(by: disposeBag)
            
        // Clear all button action
        navigationItem.rightBarButtonItem?.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showClearAllConfirmation()
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Helpers
    private func configure(cell: UITableViewCell, with task: SongDownloadTask) {
        ExperienceTheme.styleListCell(cell)
        cell.textLabel?.text = task.song.name
        let status = statusText(for: task)
        cell.detailTextLabel?.text = [task.song.artist, status]
            .filter { !$0.isEmpty }
            .joined(separator: " • ")
        cell.accessoryType = task.status.value == .completed ? .disclosureIndicator : .none
        cell.selectionStyle = [.completed, .paused, .failed, .cancelled].contains(task.status.value)
            ? .default
            : .none
        cell.accessibilityLabel = [task.song.name, task.song.artist, status]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        if let url = NetworkManager.shared.secureContentURL(from: task.song.pic_url) {
            cell.imageView?.kf.setImage(with: url, placeholder: Asset.image(named: "placeholder"))
        }
    }

    private func statusText(for task: SongDownloadTask) -> String {
        switch task.status.value {
        case .waiting:
            return L10n.downloadWaiting
        case .downloading:
            return String(
                format: L10n.downloadProgressFormat,
                L10n.downloadInProgress,
                Int(task.progress.value * 100)
            )
        case .paused:
            return L10n.downloadPaused
        case .completed:
            return L10n.downloadCompleted
        case .failed:
            return L10n.downloadFailed
        case .cancelled:
            return L10n.downloadCancelledState
        }
    }
    
    private func createEmptyStateView() -> UIView {
        ExperienceEmptyStateView(message: L10n.noDownloads, systemImage: "arrow.down.circle")
    }

    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: L10n.confirmClear,
            message: L10n.clearDownloadsMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.confirm, style: .destructive, handler: { [dataCenter] _ in
            ExperienceFeedback.selection()
            dataCenter.clearAllDownloads()
        }))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ExperienceMotion.reveal(cell: cell)
    }
}

#endif
