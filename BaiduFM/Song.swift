//
//  Song.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class Song:NSObject{
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
    
    init(sid:String,name:String,artist:String,album:String,song_url:String,pic_url:String,lrc_url:String,time:Int,is_dl:Int,dl_file:String,is_like:Int,is_recent:Int) {

        self.sid = sid
        self.name = name
        self.artist = artist
        self.album = album
        self.song_url = song_url
        self.pic_url = pic_url
        self.lrc_url = lrc_url
        self.time = time
        self.is_dl = is_dl
        self.dl_file = dl_file
        self.is_like = is_like
        self.is_recent = is_recent
        
        super.init()
    }
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