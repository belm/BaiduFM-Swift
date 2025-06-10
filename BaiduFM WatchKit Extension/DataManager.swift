//
//  DataManager.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/26.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class DataManager {
    
    // 使用现代的单例模式
    static let shared = DataManager()
    
    // 移除了废弃的 MPMoviePlayerController
    var curPlayStatus = 0 //0初始 1播放 2暂时 3停止
    
    var chid = "public_tuijian_rege"{
        didSet{
            // 使用现代的 UserDefaults API
            UserDefaults.standard.setValue(self.chid, forKey: "LAST_PLAY_CHANNEL_ID")
            UserDefaults.standard.synchronize()
        }
    }
    var chList:[Channel] = []  //类型列表
    var allSongIdList:[String] = [] //当前类别所有歌曲ID，包括没加载 info信息的
    var songInfoList:[SongInfo] = []//当前类别加载info信息的歌曲列表
    
    var curIndex = 0 {
        didSet{
            
            if curIndex >= self.songInfoList.count {
                curIndex = self.songInfoList.count-1
            }
            
            if curIndex < 0 {
                curIndex = 0
            }
            
            self.curSongInfo = self.songInfoList[self.curIndex]
        }
    }
    var curSongInfo:SongInfo? = nil
    var curSongLink:SongLink? = nil
    
    var curLrcInfo:[(lrc:String,time:Int)] = []
    
    // 使用async/await重构
    @available(iOS 13.0, *)
    func getTop20SongInfoList() async {
        do {
            let songIdList = try await HttpRequest.getSongListAsync(ch_name: DataManager.shared.chid)
            DataManager.shared.allSongIdList = songIdList
            
            let songlist20 = Array(songIdList.prefix(20))
            let sInfoList = try await HttpRequest.getSongInfoListAsync(chidArray: songlist20)
            
            await MainActor.run {
                print("getTop20SongInfoList")
                DataManager.shared.songInfoList = sInfoList
                DataManager.shared.curIndex = 0
                // 在这里可以发送通知或调用闭包来更新UI
            }
        } catch {
            print("Failed to get top 20 song info list: \(error)")
        }
    }
}