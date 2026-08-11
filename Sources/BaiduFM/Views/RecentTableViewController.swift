#if canImport(UIKit)
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

// MARK: - Recent Songs View Controller
class RecentTableViewController: UITableViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private let dataCenter = DataCenter.shared

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh recent songs every time the view appears
        dataCenter.loadRecentSongs()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = L10n.recents
        tableView.rowHeight = 60
        tableView.dataSource = nil
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(title: L10n.clearAll, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Data binding
        dataCenter.recentSongs
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { [weak self] _, song, cell in
                self?.configure(cell: cell, with: song)
            }
            .disposed(by: disposeBag)
            
        // Empty state handling
        dataCenter.recentSongs
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] hasSongs in
                self?.tableView.backgroundView = hasSongs ? nil : self?.createEmptyStateView()
            })
            .disposed(by: disposeBag)
            
        // Row selection
        tableView.rx.modelSelected(Song.self)
            .subscribe(onNext: { [weak self] song in
                self?.dataCenter.playSong(song: song)
                self?.tabBarController?.selectedIndex = 0
            })
            .disposed(by: disposeBag)
            
        // Row deletion
        tableView.rx.itemDeleted
            .map { [dataCenter] indexPath in dataCenter.recentSongs.value[indexPath.row] }
            .subscribe(onNext: { [dataCenter] song in
                dataCenter.removeSongFromRecents(songId: song.sid)
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

    private func configure(cell: UITableViewCell, with song: Song) {
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        if let url = URL(string: song.pic_url) {
            cell.imageView?.kf.setImage(with: url, placeholder: Asset.image(named: "placeholder"))
        }
    }
    
    private func createEmptyStateView() -> UIView {
        let label = UILabel()
        label.text = L10n.noRecents
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }

    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: L10n.confirmClear,
            message: L10n.clearRecentsMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.confirm, style: .destructive, handler: { [dataCenter] _ in
            dataCenter.clearRecentSongs()
        }))
        present(alert, animated: true)
    }
}

#endif
