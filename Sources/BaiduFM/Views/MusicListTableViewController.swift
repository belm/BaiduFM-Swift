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

// MARK: - Music List View Controller
class MusicListTableViewController: UITableViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var songs: [SongInfo] = []
    private var isLoading = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindData()
        loadInitialData()
    }
    
    // MARK: - Private Methods
    
    private func setupUI() {
        title = L10n.songList
        ExperienceTheme.styleList(tableView)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }
    
    private func bindData() {
        DataCenter.shared.currentSongInfoList
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] songInfoList in
                self?.songs = songInfoList
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()
                self?.isLoading = false
                self?.tableView.backgroundView = songInfoList.isEmpty
                    ? ExperienceEmptyStateView(message: L10n.noData, systemImage: "music.note.list")
                    : nil
            })
            .disposed(by: disposeBag)
        
        DataCenter.shared.currentChannel
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] channel in
                let channelName = channel?.name ?? ""
                self?.title = channelName.isEmpty ? L10n.songList : channelName
            })
            .disposed(by: disposeBag)
    }
    
    private func loadInitialData() {
        guard !isLoading else { return }
        
        let currentChannel = DataCenter.shared.currentChannel.value
        guard currentChannel != nil else {
            showErrorAlert(message: L10n.chooseChannel)
            return
        }
        
        isLoading = true
        refreshControl?.beginRefreshing()
        
        DataCenter.shared.loadSongList()
            .flatMap { _ in
                return DataCenter.shared.loadSongDetails()
            }
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    print("Song list loaded successfully")
                },
                onError: { [weak self] error in
                    print("Failed to load songs: \(error.localizedDescription)")
                    self?.refreshControl?.endRefreshing()
                    self?.isLoading = false
                    self?.showErrorAlert(message: L10n.loadSongsFailed)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func loadMoreSongs() {
        guard !isLoading else { return }
        
        isLoading = true
        
        DataCenter.shared.loadMoreSongs()
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    print("Loaded more songs successfully")
                },
                onError: { [weak self] error in
                    print("Failed to load more songs: \(error.localizedDescription)")
                    self?.isLoading = false
                    self?.showErrorAlert(message: L10n.loadMoreSongsFailed)
                }
            )
            .disposed(by: disposeBag)
    }
    
    @objc private func handleRefresh() {
        DataCenter.shared.currentStartIndex.accept(0)
        DataCenter.shared.currentEndIndex.accept(20)
        loadInitialData()
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: L10n.error, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.ok, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Memory Management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Memory warning received - MusicListTableViewController")
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
        
        ExperienceTheme.styleListCell(cell)
        cell.textLabel?.text = songInfo.name
        cell.detailTextLabel?.text = songInfo.artistName

        if let imageView = cell.imageView,
           let url = NetworkManager.shared.secureContentURL(from: songInfo.picUrl) {
            imageView.kf.setImage(
                with: url,
                placeholder: Asset.image(named: "placeholder"),
                options: [
                    .transition(.fade(0.2)),
                    .cacheOriginalImage
                ]
            )
        }
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityLabel = [songInfo.name, songInfo.artistName]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        ExperienceFeedback.selection()
        DataCenter.shared.playSong(at: indexPath.row)

        NotificationCenter.default.post(
            name: .channelMusicListClick,
            object: nil
        )
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        ExperienceMotion.reveal(cell: cell)

        if songs.count >= 3, indexPath.row == songs.count - 3 {
            loadMoreSongs()
        }
    }
}

#endif
