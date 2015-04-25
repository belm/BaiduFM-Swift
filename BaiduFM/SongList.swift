//
//  SongList.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class SongList:BaseDb {
    
    func getAll()->[Song]?{
        if self.open(){
            var sql = "SELECT * FROM tbl_song_list"
            if let rs = self.db.executeQuery(sql, withArgumentsInArray: nil){
                return self.fetchResult(rs)
            }
        }
        return nil
    }
    
    func get(sid:String)->[Song]?{
        if self.open(){
            var sql = "SELECT * FROM tbl_song_list WHERE sid=?"
            if let rs = self.db.executeQuery(sql, withArgumentsInArray: [sid]){
                return self.fetchResult(rs)
            }
        }
        return nil
    }
    
    func getAllDownload()->[Song]?{
        if self.open(){
            var sql = "SELECT * FROM tbl_song_list WHERE is_dl=1"
            if let rs = self.db.executeQuery(sql, withArgumentsInArray: nil){
                return self.fetchResult(rs)
            }
        }
        return nil
    }
    
    func getAllLike()->[Song]?{
        if self.open(){
            var sql = "SELECT * FROM tbl_song_list WHERE is_like=1"
            if let rs = self.db.executeQuery(sql, withArgumentsInArray: nil){
                return self.fetchResult(rs)
            }
        }
        return nil
    }
    
    func getAllRecent()->[Song]?{
        if self.open(){
            var sql = "SELECT * FROM tbl_song_list WHERE is_recent=1 ORDER BY id DESC LIMIT 20 OFFSET 0"
            if let rs = self.db.executeQuery(sql, withArgumentsInArray: nil){
                return self.fetchResult(rs)
            }
        }
        return nil
    }
    
    func fetchResult(rs:FMResultSet)->[Song]{
        
        // id:String name:String artist:String album:String song_url:String pic_url:String
        //lrc_url:String time:Int is_dl:Int dl_file:String is_like:Int is_recent:Int
        var ret:[Song] = []
        while rs.next(){
            
            let sid = String(Int(rs.intForColumn("sid")))
            let name = rs.stringForColumn("name") as String
            let artist = rs.stringForColumn("artist") as String
            let album = rs.stringForColumn("album") as String
            let song_url = rs.stringForColumn("song_url") as String
            let pic_url = rs.stringForColumn("pic_url") as String
            let lrc_url = rs.stringForColumn("lrc_url") as String
            let time = Int(rs.intForColumn("time"))
            let is_dl = Int(rs.intForColumn("is_dl"))
            let dl_file_tmp = rs.stringForColumn("dl_file")
            let is_like = Int(rs.intForColumn("is_like"))
            let is_recent = Int(rs.intForColumn("is_recent"))
            let format = rs.stringForColumn("format")
            
            var dl_file = ""
            if dl_file_tmp != nil {
                dl_file = dl_file_tmp as String
            }
            
            var song = Song(sid: sid, name: name, artist: artist, album: album, song_url: song_url, pic_url: pic_url, lrc_url: lrc_url, time: time, is_dl: is_dl, dl_file: dl_file, is_like: is_like, is_recent: is_recent,format:format)
            
            ret.append(song)
        }
        self.close()
        return ret
    }
    
    func insert(info:SongInfo, link:SongLink)->Bool{
        if self.open(){
            
            var song = self.get(info.id)!
            
            if song.count >= 1 {
                println("\(info.id)已经添加")
                return false
            }
            
            if self.open(){
                var sql = "INSERT INTO tbl_song_list(sid,name,artist,album,song_url,pic_url,lrc_url,time,format) VALUES(?,?,?,?,?,?,?,?,?)"
                
                var songUrl = Common.getCanPlaySongUrl(link.songLink)
                var img = Common.getIndexPageImage(info)
                
                var args:[AnyObject] = [info.id,info.name,info.artistName,info.albumName,songUrl,img,link.lrcLink,link.time,link.format]
                var ret = self.db.executeUpdate(sql, withArgumentsInArray: args)
                self.close()
                return ret
            }
        }
        return false
    }
    
    func delete(sid:String)->Bool{
        if self.open(){
            var sql = "DELETE FROM tbl_song_list WHERE sid=?"
            var ret = self.db.executeUpdate(sql, withArgumentsInArray: [sid])
            self.close()
            return ret
        }
        return false
    }
    
    func cleanDownloadList()->Bool{
        if self.open(){
            var sql = "update tbl_song_list set is_dl = 0"
            var ret = self.db.executeUpdate(sql, withArgumentsInArray: nil)
            self.close()
            return ret
        }
        return false
    }
    
    func updateDownloadStatus(sid:String)->Bool{
        if self.open(){
            var sql = "UPDATE tbl_song_list set is_dl=1 WHERE sid=?"
            var ret = self.db.executeUpdate(sql, withArgumentsInArray: [sid])
            self.close()
            return ret
        }
        return false
    }
    
    func updateLikeStatus(sid:String, status:Int)->Bool{
        // status = 0 取消喜欢  1喜欢
        if status != 0 && status != 1 {return false}
        
        if self.open(){
            var sql = "UPDATE tbl_song_list set is_like=? WHERE sid=?"
            var ret = self.db.executeUpdate(sql, withArgumentsInArray: [status,sid])
            self.close()
            return ret
        }
        return false
    }
    
    //清理最近播放列表，只保留最近20首歌曲
    func clearRecentPlayList(){
    
    }
}