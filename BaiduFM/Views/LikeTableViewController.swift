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
        title = "My Likes"
        tableView.rowHeight = 60
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "likeCell")
    }
    
    private func setupNavigationBar() {
        let clearButton = UIBarButtonItem(title: "Clear All", style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = clearButton
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        // Data binding
        dataCenter.likedSongs
            .asDriver(onErrorJustReturn: [])
            .drive(tableView.rx.items(cellIdentifier: "likeCell", cellType: UITableViewCell.self)) { (row, song, cell) in
                self.configure(cell: cell, with: song)
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
                self?.dataCenter.playSong(song: song) // Assuming a method to play a specific song object
                self?.tabBarController?.selectedIndex = 0
            })
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
        cell.textLabel?.text = song.name
        cell.detailTextLabel?.text = song.artist
        if let url = URL(string: song.pic_url) {
            cell.imageView?.kf.setImage(with: url, placeholder: UIImage(named: "placeholder"))
        }
    }
    
    private func createEmptyStateView() -> UIView {
        let label = UILabel()
        label.text = "You haven't liked any songs yet.\nTap the heart icon on the player screen to add."
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }

    private func showClearAllConfirmation() {
        let alert = UIAlertController(
            title: "Confirm Clear",
            message: "Are you sure you want to clear all liked songs? This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { [dataCenter] _ in
            dataCenter.clearLikedSongs()
        }))
        present(alert, animated: true)
    }
}
