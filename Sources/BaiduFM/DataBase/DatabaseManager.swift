//
//  DatabaseManager.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//
//  Refactored by AI on 2024-07-25.
//

import Foundation
import Cfmdb

/// 数据库管理器，采用单例模式，并使用FMDatabaseQueue保证线程安全
final class DatabaseManager {
    
    /// 共享的单例实例
    static let shared = DatabaseManager()
    
    /// 数据库队列，用于线程安全地执行数据库操作
    let queue: FMDatabaseQueue
    
    /// 私有化构造器，确保全局只有一个实例
    private init() {
        // 获取数据库文件路径
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = (documentsPath as NSString).appendingPathComponent("music.db")
        
        // 初始化数据库队列
        self.queue = FMDatabaseQueue(path: dbPath)!
        
        // 创建数据表
        createTables()
    }
    
    /// 创建应用所需的数据表
    private func createTables() {
        // 使用inDatabase方法来保证线程安全
        queue.inDatabase { db in
            // 安全解包数据库连接
            guard let database = db else {
                print("无法获取数据库连接")
                return
            }
            
            let sql = """
            CREATE TABLE IF NOT EXISTS tbl_song_list (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sid TEXT UNIQUE,
                name TEXT,
                artist TEXT,
                album TEXT,
                song_url TEXT,
                pic_url TEXT,
                lrc_url TEXT,
                time INTEGER,
                is_dl INTEGER DEFAULT 0,
                dl_file TEXT,
                is_like INTEGER DEFAULT 0,
                is_recent INTEGER DEFAULT 0,
                format TEXT
            );
            """
            
            if !database.executeStatements(sql) {
                print("创建表 tbl_song_list 失败: \(database.lastErrorMessage())")
            } else {
                print("创建/检查表 tbl_song_list 成功")
            }
        }
    }
} 