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

/// Owns the serialized database queue and applies lightweight schema migrations.
final class DatabaseManager {

    static let shared = DatabaseManager()

    let queue: FMDatabaseQueue

    private init() {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let dbPath = (documentsPath as NSString).appendingPathComponent("music.db")

        self.queue = FMDatabaseQueue(path: dbPath)!
        createTables()
    }

    private func createTables() {
        queue.inDatabase { db in
            guard let database = db else {
                print("Unable to acquire the database connection")
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
                last_played_at REAL DEFAULT 0,
                format TEXT
            );
            """
            
            if !database.executeStatements(sql) {
                print("Failed to create tbl_song_list: \(database.lastErrorMessage() ?? "Unknown error")")
            }

            var hasLastPlayedAt = false
            if let columns = database.executeQuery("PRAGMA table_info(tbl_song_list)", withArgumentsIn: []) {
                while columns.next() {
                    if columns.string(forColumn: "name") == "last_played_at" {
                        hasLastPlayedAt = true
                        break
                    }
                }
                columns.close()
            }
            if !hasLastPlayedAt {
                let migration = "ALTER TABLE tbl_song_list ADD COLUMN last_played_at REAL DEFAULT 0"
                if !database.executeUpdate(migration, withArgumentsIn: []) {
                    print("Failed to add playback history ordering: \(database.lastErrorMessage() ?? "Unknown error")")
                }
            }

            let recentIndex = "CREATE INDEX IF NOT EXISTS idx_song_recent_played ON tbl_song_list(is_recent, last_played_at DESC)"
            if !database.executeUpdate(recentIndex, withArgumentsIn: []) {
                print("Failed to index playback history: \(database.lastErrorMessage() ?? "Unknown error")")
            }
        }
    }
}
