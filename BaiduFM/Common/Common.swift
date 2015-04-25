//
//  Common.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/15.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class Common {
    
    /**
    获取可以播放的音乐
    
    :param: url 音乐播放URL
    
    :returns: 可以播放的URL
    */
    class func getCanPlaySongUrl(url: String)->String{
        
        if url.hasPrefix("http://file.qianqian.com"){
            return replaceString("&src=.+", replace: url, place: "")!
            //return url.substringToIndex(advance(url.startIndex, 114))
        }
        return url
    }
    
    /**
    获取首页显示图片
    
    :param: info 歌曲信息
    
    :returns: 首页显示的图片
    */
    class func getIndexPageImage(info :SongInfo) -> String{
        
        if info.songPicBig.isEmpty == false {
            return info.songPicBig
        }
        
        if info.songPicRadio.isEmpty == false {
            return info.songPicRadio
        }
        
        return info.songPicSmall
    }
    
    /**
    获取友好显示的时间
    
    :param: seconds 秒数
    
    :returns: 友好的时间显示
    */
    class func getMinuteDisplay(seconds: Int) ->String{
        
        var minute = Int(seconds/60)
        var second = seconds%60
        
        var minuteStr = minute >= 10 ? String(minute) : "0\(minute)"
        var secondStr = second >= 10 ? String(second) : "0\(second)"
        
        return "\(minuteStr):\(secondStr)"
    }
    
    /**
    正则替换字符串
    
    :param: pattern 正则表达式
    :param: replace 需要被替换的字符串
    :param: place   用来替换的字符串
    
    :returns: 替换后的字符串
    */
    class func replaceString(pattern:String, replace:String, place:String)->String?{
        
        var exp =  NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        return exp?.stringByReplacingMatchesInString(replace, options: nil, range: NSRange(location: 0,length: count(replace)), withTemplate: place)
    }
    
    class func fileIsExist(filePath:String)->Bool{
        return NSFileManager.defaultManager().fileExistsAtPath(filePath)
    }
    
    class func musicLocalPath(songId:String, format:String) -> String{
        
        var musicDir = Utils.documentPath().stringByAppendingPathComponent("download")
        if !NSFileManager.defaultManager().fileExistsAtPath(musicDir){
            NSFileManager.defaultManager().createDirectoryAtPath(musicDir, withIntermediateDirectories: false, attributes: nil, error: nil)
        }
        var musicPath = musicDir.stringByAppendingPathComponent(songId + "." + format)
        return musicPath
    }
    
    class func cleanAllDownloadSong(){
       
        //删除歌曲文件夹
        var musicDir = Utils.documentPath().stringByAppendingPathComponent("download")
        NSFileManager.defaultManager().removeItemAtPath(musicDir, error: nil)
        
    }
    
    class func deleteSong(songId:String, format:String)->Bool{
        //删除本地歌曲
        var musicPath = self.musicLocalPath(songId, format: format)
        var ret = NSFileManager.defaultManager().removeItemAtPath(musicPath, error: nil)
        return ret
    }

}