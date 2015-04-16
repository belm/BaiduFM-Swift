//
//  Common.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/15.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class Common {
    
    class func getCanPlaySongUrl(url: String)->String{
        
        if url.hasPrefix("http://file.qianqian.com"){
            return url.substringToIndex(advance(url.startIndex, 114))
        }
        return url
    }
    
    class func getIndexPageImage(info :SongInfo) -> String{
        
        if info.songPicBig.isEmpty == false {
            return info.songPicBig
        }
        
        if info.songPicRadio.isEmpty == false {
            return info.songPicRadio
        }
        
        return info.songPicSmall
    }
    
    class func getMinuteDisplay(seconds: Int) ->String{
        
        var minute = Int(seconds/60)
        var second = seconds%60
        
        var minuteStr = minute >= 10 ? String(minute) : "0\(minute)"
        var secondStr = second >= 10 ? String(second) : "0\(second)"
        
        return "\(minuteStr):\(secondStr)"
    }
    
    class func replaceString(pattern:String, replace:String, place:String)->String?{
        
        var exp =  NSRegularExpression(pattern: pattern, options: NSRegularExpressionOptions.CaseInsensitive, error: nil)
        return exp?.stringByReplacingMatchesInString(replace, options: nil, range: NSRange(location: 0,length: count(replace)), withTemplate: place)
    }
}