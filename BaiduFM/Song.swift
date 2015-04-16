//
//  Song.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

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