#if canImport(UIKit)
//
//  LikeTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Kingfisher

// MARK: - Liked Songs View Controller
class LikeTableViewController: UITableViewController {
    
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
        // Refresh liked songs every time the view appears
        dataCenter.loadLikedSongs()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = L10n.likes
        ExperienceTheme.styleList(tableView)
        tableView.dataSource = nil
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(title: L10n.clearAll, style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Data binding
        dataCenter.likedSongs
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { [weak self] _, song, cell in
                self?.configure(cell: cell, with: song)
            }
            .disposed(by: disposeBag)
            
        // Empty state handling
        dataCenter.likedSongs
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] hasSongs in
                self?.tableView.backgroundView = hasSongs ? nil : self?.createEmptyStateView()
            })
            .disposed(by: disposeBag)
            
        // Row selection
        tableView.rx.modelSelected(Song.self)
            .subscribe(onNext: { [weak self] song in
                ExperienceFeedback.selection()
                self?.dataCenter.playSong(song: song)
                self?.tabBarController?.selectedIndex = 0
            })
            .disposed(by: disposeBag)

        dataCenter.likedSongs
            .map { !$0.isEmpty }
            .asDriver(onErrorJustReturn: false)
            .drive(navigationItem.rightBarButtonItem!.rx.isEnabled)
            .disposed(by: disposeBag)
            
        // Row deletion
        tableView.rx.itemDeleted
            .map { [dataCenter] indexPath in dataCenter.likedSongs.value[indexPath.row] }
            .subscribe(onNext: { [dataCenter] song in
                dataCenter.removeSongFromLikes(songId: song.sid)
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
        ExperienceTheme.styleListCell(cell)
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityLabel = [song.name, song.artist].filter { !$0.isEmpty }.joined(separator: ", ")
        if let url = NetworkManager.shared.secureContentURL(from: song.pic_url) {
            cell.imageView?.kf.setImage(with: url, placeholder: Asset.image(named: "placeholder"))
        }
    }
    
    private func createEmptyStateView() -> UIView {
        ExperienceEmptyStateView(message: L10n.noLikes, systemImage: "heart")
    }

    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: L10n.confirmClear,
            message: L10n.clearLikesMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: L10n.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.confirm, style: .destructive, handler: { [dataCenter] _ in
            ExperienceFeedback.selection()
            dataCenter.clearLikedSongs()
        }))
        present(alert, animated: true)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ExperienceMotion.reveal(cell: cell)
    }
}

#endif
