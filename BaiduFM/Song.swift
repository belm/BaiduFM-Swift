//
//  Song.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

struct Song{
    var sid:String
    var name:String
    var artist:String
    var album:String
    var song_url:String
    var pic_url:String
    var lrc_url:String
    var time:Int
    var is_dl:Int
    var dl_file:String
    var is_like:Int
    var is_recent:Int
}

struct SongInfo {
    var id:String
    var name:String
    var artistId:String
    var artistName:String
    var albumId:Int
    var albumName:String
    var songPicSmall:String
    var songPicBig:String
    var songPicRadio:String
    var allRate:String
}

struct SongLink {
    var id:String
    var name:String
    var lrcLink:String
    var linkCode:Int
    var songLink:String
    var format:String
    var time:Int
    var size:Int
    var rate:Int
}