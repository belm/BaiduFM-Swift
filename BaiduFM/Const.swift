//
//  Const.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/23.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

// MARK: - 通知
let CHANNEL_MUSIC_LIST_CLICK_NOTIFICATION = "CHANNEL_MUSIC_LIST_CLICK_NOTIFICATION" //某类别歌曲列表点击通知

let OTHER_MUSIC_LIST_CLICK_NOTIFICATION = "OTHER_MUSIC_LIST_CLICK_NOTIFICATION" //下载，喜欢，最近播放列表点击通知

// MARK: - 常量

//获取歌曲分类列表
let http_channel_list_url = "http://fm.baidu.com/dev/api/?tn=channellist&hashcode=310d03041bffd10803bc3ee8913e2726&_=1428801468750"

//获取某个分类歌曲类别 http_song_list_url + "分类名"
let http_song_list_url = "http://fm.baidu.com/dev/api/?tn=playlist&hashcode=310d03041bffd10803bc3ee8913e2726&_=1428917601565&id="

//获取歌曲info信息
let http_song_info = "http://fm.baidu.com/data/music/songinfo"

//获取歌曲link信息
let http_song_link = "http://fm.baidu.com/data/music/songlink"

//获取歌词 http://fm.baidu.com/data2/lrc/14881153/14881153.lrc
let http_song_lrc = "http://fm.baidu.com"

