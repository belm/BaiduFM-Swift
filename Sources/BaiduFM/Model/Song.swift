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
    var format:String
    
    init(sid:String,name:String,artist:String,album:String,song_url:String,pic_url:String,lrc_url:String,time:Int,is_dl:Int,dl_file:String,is_like:Int,is_recent:Int,format:String) {

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
        self.format = format
        
        super.init()
    }
    
    convenience init(sid: String, name: String, url: String, pic_url: String, lrc_url: String, artist: String, album: String, format: String, time: Int) {
        self.init(sid: sid, name: name, artist: artist, album: album, song_url: url, pic_url: pic_url, lrc_url: lrc_url, time: time, is_dl: 0, dl_file: "", is_like: 0, is_recent: 0, format: format)
    }
}

