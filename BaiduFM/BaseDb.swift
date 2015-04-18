//
//  BaseDb.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class BaseDb {
    
    var dbPath: String
    var db:FMDatabase
    
    init(){
        
        println("basedb init")
        var dbDirectory = Utils.documentPath().stringByAppendingPathComponent("database")
        
        if !NSFileManager.defaultManager().fileExistsAtPath(dbDirectory){
                NSFileManager.defaultManager().createDirectoryAtPath(dbDirectory, withIntermediateDirectories: false, attributes: nil, error: nil)
        }
        
        self.dbPath = dbDirectory.stringByAppendingPathComponent("baidufm.sqlite")
        
        self.db = FMDatabase(path: self.dbPath)
        //println(dbPath)
        
        //db文件不存在则创建
        if !NSFileManager.defaultManager().fileExistsAtPath(self.dbPath){
            if self.open() {
                var sql = "CREATE TABLE tbl_song_list (id INTEGER PRIMARY KEY AUTOINCREMENT,sid TEXT UNIQUE,name TEXT,artist TEXT,album TEXT,song_url  TEXT,pic_url   TEXT,lrc_url TEXT,time INTEGER,is_dl INTEGER DEFAULT 0,dl_file TEXT,is_like INTEGER DEFAULT 0,is_recent INTEGER DEFAULT 1)"
                if !self.db.executeUpdate(sql, withArgumentsInArray: nil){
                    println("db创建失败")
                }else{
                    println("db创建成功")
                }
            }else{
                println("open error")
            }
        }
    }
    
    deinit{
        self.close()
    }
    
    func open()->Bool{
        return self.db.open()
    }
    
    func close()->Bool{
        return self.db.close()
    }
}