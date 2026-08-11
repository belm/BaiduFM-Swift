#if canImport(UIKit)
//
//  AppDelegate.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import AVFoundation

final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupAudioSession()
        _ = DatabaseManager.shared
        return true
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
            if audioManager.isPlaying {
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
                options: [.allowAirPlay, .allowBluetoothA2DP, .allowBluetoothHFP]
            )
            // 激活音频会话
            try audioSession.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error.localizedDescription)")
        }
    }
}

#endif
