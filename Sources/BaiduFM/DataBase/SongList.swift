//
//  SongList.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation
import Cfmdb

/// 歌曲数据库操作类，专门用于操作歌曲数据的服务类
class SongList {
    
    /// 获取数据库队列的便捷属性
    private var queue: FMDatabaseQueue {
        return DatabaseManager.shared.queue
    }
    
    /// 获取所有歌曲
    func getAll() -> [Song]? {
        var songs: [Song]?
        // 在数据库队列中同步执行查询，保证线程安全
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "SELECT * FROM tbl_song_list"
            if let rs = database.executeQuery(sql, withArgumentsIn: []) {
                songs = self.fetchResult(rs: rs)
            }
        }
        return songs
    }
    
    /// 根据歌曲ID获取单首歌曲
    func get(sid: String) -> Song? {
        var song: Song?
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "SELECT * FROM tbl_song_list WHERE sid=?"
            if let rs = database.executeQuery(sql, withArgumentsIn: [sid]) {
                if let fetchedSongs = self.fetchResult(rs: rs), !fetchedSongs.isEmpty {
                    song = fetchedSongs.first
                }
            }
        }
        return song
    }
    
    /// 获取所有已下载的歌曲
    func getAllDownload() -> [Song]? {
        var songs: [Song]?
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "SELECT * FROM tbl_song_list WHERE is_dl=1"
            if let rs = database.executeQuery(sql, withArgumentsIn: []) {
                songs = self.fetchResult(rs: rs)
            }
        }
        return songs
    }
    
    /// 获取所有喜欢的歌曲
    func getAllLike() -> [Song]? {
        var songs: [Song]?
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "SELECT * FROM tbl_song_list WHERE is_like=1"
            if let rs = database.executeQuery(sql, withArgumentsIn: []) {
                songs = self.fetchResult(rs: rs)
            }
        }
        return songs
    }
    
    /// 获取所有最近播放的歌曲
    func getAllRecent() -> [Song]? {
        var songs: [Song]?
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "SELECT * FROM tbl_song_list WHERE is_recent=1 ORDER BY id DESC LIMIT 20 OFFSET 0"
            if let rs = database.executeQuery(sql, withArgumentsIn: []) {
                songs = self.fetchResult(rs: rs)
            }
        }
        return songs
    }
    
    /// 处理数据库查询结果的私有辅助方法
    private func fetchResult(rs: FMResultSet) -> [Song]? {
        var ret: [Song] = []
        while rs.next() {
            let sid = rs.string(forColumn: "sid") ?? ""
            let name = rs.string(forColumn: "name") ?? ""
            let artist = rs.string(forColumn: "artist") ?? ""
            let album = rs.string(forColumn: "album") ?? ""
            let song_url = rs.string(forColumn: "song_url") ?? ""
            let pic_url = rs.string(forColumn: "pic_url") ?? ""
            let lrc_url = rs.string(forColumn: "lrc_url") ?? ""
            let time = Int(rs.int(forColumn: "time"))
            let is_dl = Int(rs.int(forColumn: "is_dl"))
            let dl_file = rs.string(forColumn: "dl_file") ?? ""
            let is_like = Int(rs.int(forColumn: "is_like"))
            let is_recent = Int(rs.int(forColumn: "is_recent"))
            let format = rs.string(forColumn: "format") ?? ""
            
            let song = Song(sid: sid, name: name, artist: artist, album: album, song_url: song_url, pic_url: pic_url, lrc_url: lrc_url, time: time, is_dl: is_dl, dl_file: dl_file, is_like: is_like, is_recent: is_recent, format: format)
            
            ret.append(song)
        }
        // FMDatabaseQueue会自动管理连接，这里不再需要close
        return ret.isEmpty ? nil : ret
    }
    
    /// 插入新歌曲到数据库
    func insert(info: SongInfo, link: SongLink) -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            
            // 首先检查歌曲是否已存在
            let checkSql = "SELECT COUNT(*) FROM tbl_song_list WHERE sid=?"
            let count = database.scalar(forQuery: checkSql, arguments: [info.songId]) as? Int ?? 0
            if count > 0 {
                print("\(info.songId)已经添加")
                // 歌曲已存在，设置success为true或false取决于业务逻辑，这里假设不重复添加即为成功
                success = true
                return
            }
            
            let sql = "INSERT INTO tbl_song_list(sid,name,artist,album,song_url,pic_url,lrc_url,time,format) VALUES(?,?,?,?,?,?,?,?,?)"
            
            let songUrl = Common.getCanPlaySongUrl(url: link.songLink)
            let img = Common.getIndexPageImage(info: info)
            
            let args: [Any] = [info.songId, info.name, info.artistName, info.albumName, songUrl, img, link.lrcLink, link.time, link.format]
            success = database.executeUpdate(sql, withArgumentsIn: args)
        }
        return success
    }
    
    /// 根据歌曲ID删除歌曲
    func delete(sid: String) -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "DELETE FROM tbl_song_list WHERE sid=?"
            success = database.executeUpdate(sql, withArgumentsIn: [sid])
        }
        return success
    }
    
    /// 更新歌曲下载状态
    func updateDownloadStatus(sid: String, status: Int) -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "UPDATE tbl_song_list SET is_dl=? WHERE sid=?"
            success = database.executeUpdate(sql, withArgumentsIn: [status, sid])
        }
        return success
    }
    
    /// 更新歌曲喜欢状态
    func updateLikeStatus(sid: String, status: Int) -> Bool {
        // status = 0 取消喜欢  1喜欢
        if status != 0 && status != 1 { return false }
        
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "UPDATE tbl_song_list SET is_like=? WHERE sid=?"
            success = database.executeUpdate(sql, withArgumentsIn: [status, sid])
        }
        return success
    }

// MARK: - 清理方法
    /// 清空喜欢列表
    func clearLikeList() -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "UPDATE tbl_song_list SET is_like = 0"
            success = database.executeUpdate(sql, withArgumentsIn: [])
        }
        return success
    }
    
    /// 清空下载列表
    func cleanDownloadList() -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "UPDATE tbl_song_list SET is_dl = 0"
            success = database.executeUpdate(sql, withArgumentsIn: [])
        }
        return success
    }
    
    /// 清空最近播放列表
    func cleanRecentList() -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            // 在同一个事务中执行多个更新，保证原子性
            database.beginTransaction()
            let sql1 = "UPDATE tbl_song_list SET is_recent=0 WHERE is_dl = 1 OR is_like=1"
            let ret1 = database.executeUpdate(sql1, withArgumentsIn: [])
            
            let sql2 = "DELETE FROM tbl_song_list WHERE is_recent = 1"
            let ret2 = database.executeUpdate(sql2, withArgumentsIn: [])
            
            if ret1 && ret2 {
                database.commit()
                success = true
            } else {
                database.rollback()
                success = false
            }
        }
        return success
    }
    
    // MARK: - 现代化的删除方法
    
    /// 删除单个歌曲
    func deleteSong(songId: String) -> Bool {
        return delete(sid: songId)
    }
    
    /// 删除单个喜欢的歌曲
    func deleteLikeSong(songId: String) -> Bool {
        return updateLikeStatus(sid: songId, status: 0)
    }
    
    /// 删除单个最近播放的歌曲
    func deleteRecentSong(songId: String) -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "UPDATE tbl_song_list SET is_recent=0 WHERE sid=?"
            success = database.executeUpdate(sql, withArgumentsIn: [songId])
        }
        return success
    }
    
    /// 添加最近播放记录
    func addRecentSong(songId: String) -> Bool {
        var success = false
        queue.inDatabase { db in
            guard let database = db else { return }
            let sql = "UPDATE tbl_song_list SET is_recent=1 WHERE sid=?"
            success = database.executeUpdate(sql, withArgumentsIn: [songId])
        }
        return success
    }
}