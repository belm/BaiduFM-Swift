//
//  DataManager.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/26.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation
import MediaPlayer

class DataManager {
    
    //单例
    class var shareDataManager:DataManager{
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance: DataManager? = nil
        }
        
        dispatch_once(&Static.onceToken) { () -> Void in
            Static.instance = DataManager()
        }
        return Static.instance!
    }
    
    var mp:MPMoviePlayerController = MPMoviePlayerController()
    var curPlayStatus = 0 //0初始 1播放 2暂时 3停止
    
    var chid = "public_tuijian_rege"{
        didSet{
            NSUserDefaults.standardUserDefaults().setValue(self.chid, forKey: "LAST_PLAY_CHANNEL_ID")
            NSUserDefaults.standardUserDefaults().synchronize()
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
}