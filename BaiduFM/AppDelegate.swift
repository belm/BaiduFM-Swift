//
//  AppDelegate.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher

@main  // 使用@main替代@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 应用启动后的自定义配置
        
        // 配置音频会话支持后台播放
        setupAudioSession()
        
        // 启用远程控制事件接收
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // 初始化数据库单例，确保在应用启动时创建数据库和表
        let _ = DatabaseManager.shared
        
        // 配置Kingfisher图片缓存库
        setupKingfisherConfiguration()
        
        return true
    }

    // MARK: - UISceneSession Lifecycle（iOS 13+支持）
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // 场景会话被丢弃时的清理工作
    }

    // MARK: - 应用生命周期方法
    func applicationWillResignActive(_ application: UIApplication) {
        // 应用即将进入非活跃状态时的处理
        // 可以在这里暂停正在进行的任务，禁用计时器等
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // 应用进入后台时的处理
        // 保存用户数据，失效计时器，存储足够的应用状态信息以便恢复
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // 应用即将从后台进入前台时的处理
        // 可以在这里撤销进入后台时的更改
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // 应用变为活跃状态时的处理
        // 重启被暂停的任务，刷新用户界面等
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // 应用即将终止时的处理
        // 保存数据，释放资源等
        AudioManager.shared.stop()
    }
    
    // MARK: - 远程控制事件处理
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event,
              event.type == .remoteControl else { return }
        
        let audioManager = AudioManager.shared
        
        switch event.subtype {
        case .remoteControlPlay:
            audioManager.resume()
        case .remoteControlPause:
            audioManager.pause()
        case .remoteControlNextTrack:
            audioManager.playNext()
        case .remoteControlPreviousTrack:
            audioManager.playPrevious()
        case .remoteControlTogglePlayPause:
            if audioManager.playbackState.value == .playing {
                audioManager.pause()
            } else {
                audioManager.resume()
            }
        default:
            break
        }
    }
}

// MARK: - 私有配置方法
private extension AppDelegate {
    
    /// 配置音频会话
    func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            // 设置音频会话类别为播放，支持后台播放
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
            )
            // 激活音频会话
            try audioSession.setActive(true)
        } catch {
            print("音频会话配置失败: \(error.localizedDescription)")
        }
    }
    
    /// 配置Kingfisher图片缓存
    func setupKingfisherConfiguration() {
        // 获取下载器实例并配置
        let downloader = KingfisherManager.shared.downloader
        downloader.downloadTimeout = 15.0  // 下载超时时间
        downloader.sessionConfiguration.timeoutIntervalForRequest = 15.0
        
        // 获取缓存实例并配置
        let cache = KingfisherManager.shared.cache
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024  // 磁盘缓存最大200MB
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024  // 内存缓存最大50MB
        cache.diskStorage.config.expiration = .days(7)  // 磁盘缓存过期时间7天
        
        // 配置图片处理器
        let processor = DownsamplingImageProcessor(size: CGSize(width: 300, height: 300))
        KingfisherManager.shared.defaultOptions = [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .transition(.fade(0.3)),
            .cacheOriginalImage
        ]
    }
}

