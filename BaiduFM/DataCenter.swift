//
//  DataCenter.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/14.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation
import MediaPlayer

class DataCenter {
    
    //单例
    class var shareDataCenter:DataCenter{
        struct Static {
            static var onceToken : dispatch_once_t = 0
            static var instance: DataCenter? = nil
        }
        
        dispatch_once(&Static.onceToken) { () -> Void in
            Static.instance = DataCenter()
        }
        return Static.instance!
    }
    
    var mp:MPMoviePlayerController = MPMoviePlayerController()
    
    //歌曲分类列表信息
    var channelListInfo:[Channel] = []
    
    //当前分类
    var currentChannel: String = "public_tuijian_zhongguohaoshengyin"
    
    var currentChannelName: String = "中国好声音"
    
    //当前分类所有歌曲ID
    var currentAllSongId:[String] = []
    
    var curShowStartIndex = 0
    
    var curShowEndIndex = 20
    
    //当前显示歌曲列表
    var curShowAllSongId:[String]{
        get {
            return [] + currentAllSongId[curShowStartIndex ..< curShowEndIndex]
        }
    }
    
    //当前显示歌曲列表info信息
    var curShowAllSongInfo:[SongInfo] = []
    
    //当前显示歌曲列表link信息
    var curShowAllSongLink:[SongLink] = []
    
    //当前播放的歌曲index
    var curPlayIndex:Int = 0{
        didSet{
            if curPlayIndex < curShowAllSongInfo.count {
                curPlaySongInfo = curShowAllSongInfo[curPlayIndex]
            }
            
            if curPlayIndex < curShowAllSongLink.count{
                curPlaySongLink = curShowAllSongLink[curPlayIndex]
            }
        }
    }
    
    //当前播放歌曲的info信息
    var curPlaySongInfo:SongInfo? = nil
    
    //当前播放歌曲的info信息
    var curPlaySongLink:SongLink? = nil
    
    var curPlayStatus = 0 //0初始 1播放 2暂时 3停止
    
    //db操作
    var dbSongList:SongList = SongList()
}