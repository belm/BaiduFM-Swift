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
    获取可以播放的音乐 - 处理百度音乐的URL格式
    
    :param: url 音乐播放URL
    
    :returns: 可以播放的URL
    */
    class func getCanPlaySongUrl(url: String)->String{
        
        if url.hasPrefix("http://file.qianqian.com"){
            return replaceString(pattern: "&src=.+", replace: url, place: "")!
            //return url.substringToIndex(advance(url.startIndex, 114))
        }
        return url
    }
    
    /**
    获取首页显示图片 - 根据优先级选择合适的图片尺寸
    
    :param: info 歌曲信息
    
    :returns: 首页显示的图片URL
    */
    class func getIndexPageImage(info :SongInfo) -> String{
        
        // 使用统一的picUrl属性
        return info.picUrl
    }
    
    /**
    获取友好显示的时间 - 将秒数转换为MM:SS格式
    
    :param: seconds 秒数
    
    :returns: 友好的时间显示
    */
    class func getMinuteDisplay(seconds: Int) ->String{
        
        let minute = Int(seconds/60)
        let second = seconds%60
        
        let minuteStr = minute >= 10 ? String(minute) : "0\(minute)"
        let secondStr = second >= 10 ? String(second) : "0\(second)"
        
        return "\(minuteStr):\(secondStr)"
    }
    
    /**
    正则替换字符串 - 使用现代Swift正则表达式API
    
    :param: pattern 正则表达式
    :param: replace 需要被替换的字符串
    :param: place   用来替换的字符串
    
    :returns: 替换后的字符串
    */
    class func replaceString(pattern: String, replace: String, place: String) -> String? {
        // 创建正则表达式（忽略大小写），Swift 5 需要使用 try? 语法
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(location: 0, length: replace.utf16.count)
        return regex.stringByReplacingMatches(in: replace, options: [], range: range, withTemplate: place)
    }
    
    /// 检查文件是否存在 - 使用现代FileManager API
    class func fileIsExist(filePath:String)->Bool{
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    /// 获取音乐本地存储路径 - 使用现代路径API
    class func musicLocalPath(songId:String, format:String) -> String{
        
        let musicDir = (Utils.documentPath() as NSString).appendingPathComponent("download")
        if !FileManager.default.fileExists(atPath: musicDir){
            try? FileManager.default.createDirectory(atPath: musicDir, withIntermediateDirectories: false, attributes: nil)
        }
        let musicPath = (musicDir as NSString).appendingPathComponent(songId + "." + format)
        return musicPath
    }
    
    /// 清理所有下载的歌曲 - 删除整个下载文件夹
    class func cleanAllDownloadSong(){
       
        //删除歌曲文件夹
        let musicDir = (Utils.documentPath() as NSString).appendingPathComponent("download")
        try? FileManager.default.removeItem(atPath: musicDir)
        
    }
    
    /// 删除指定歌曲文件 - 删除单个歌曲文件
    class func deleteSong(songId:String, format:String)->Bool{
        //删除本地歌曲
        let musicPath = self.musicLocalPath(songId: songId, format: format)
        do {
            try FileManager.default.removeItem(atPath: musicPath)
            return true
        } catch {
            return false
        }
    }
    
    class func matchesForRegexInText(_ regex: String, text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        return results.map { nsString.substring(with: $0.range) }
    }
    
    //02:57 => 2*60+57=177
    class func timeStringToSecond(_ time: String) -> Int? {
        let components = time.split(separator: ":")
        guard components.count >= 2, let minutes = Int(components[0]), let seconds = Int(components[1]) else { return nil }
        return minutes * 60 + seconds
    }
    
    /// 字符串截取工具（从 start 开始截取 length 个字符）
    class func subStr(_ str: String, start: Int, length: Int) -> String {
        guard start >= 0, length > 0, start + length <= str.count else { return "" }
        let startIndex = str.index(str.startIndex, offsetBy: start)
        let endIndex = str.index(startIndex, offsetBy: length)
        return String(str[startIndex..<endIndex])
    }
    
    /// 解析歌词，返回 (歌词, 时间秒数) 元组数组
    class func praseSongLrc(lrc: String) -> [(lrc: String, time: Int)] {
        let list = lrc.split(separator: "\n").map(String.init)
        var ret: [(lrc: String, time: Int)] = []
        
        for row in list {
            // 匹配 [] 中的时间标记
            let timeArray = matchesForRegexInText("(\\[\\d{2}\\:\\d{2}\\.\\d{2}\\])", text: row)
            let lrcArray = matchesForRegexInText("\\](.*)", text: row)
            guard !timeArray.isEmpty else { continue }
            let lrcTime = timeArray[0] // e.g. [02:57.26]
            
            var lrcTxt = ""
            if let txtPart = lrcArray.first {
                lrcTxt = txtPart
                if lrcTxt.hasPrefix("]") {
                    lrcTxt.removeFirst()
                }
            }
            // 取 mm:ss 部分
            let timeStr = subStr(lrcTime, start: 1, length: 5)
            if let t = timeStringToSecond(timeStr) {
                ret.append((lrc: lrcTxt, time: t))
            }
        }
        return ret
    }
    
    /// 根据当前播放进度返回当前行和下一行歌词
    class func currentLrcByTime(curLength: Int, lrcArray: [(lrc: String, time: Int)]) -> (String, String) {
        for (index, tuple) in lrcArray.enumerated() {
            let (lrc, time) = tuple
            if time >= curLength {
                if index == 0 { return (lrc, "") }
                let prev = lrcArray[index - 1]
                return (prev.lrc, lrc)
            }
        }
        return ("", "")
    }
    
    // MARK: - 现代化的文件管理方法
    
    /// 删除下载的歌曲文件
    class func deleteDownloadedSong(song: Song) -> Bool {
        let musicPath = musicLocalPath(songId: song.sid, format: song.format)
        do {
            try FileManager.default.removeItem(atPath: musicPath)
            return true
        } catch {
            return false
        }
    }
    
    /// 获取数据库路径
    class func getDbPath() -> String {
        let documentsPath = Utils.documentPath()
        let dbPath = (documentsPath as NSString).appendingPathComponent("music.db")
        return dbPath
    }

}