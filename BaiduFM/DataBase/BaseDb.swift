//
//  BaseDb.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation
import fmdb

let dbPath = Common.getDbPath()

class BaseDb {
    
    var db:FMDatabase
    
    init(){
        self.db = FMDatabase(path: dbPath)
        print("basedb init")
    }
    
    func createTable(sql:String)->Bool{
        
        //print(dbPath)
        
        if self.db.open() {
            if !self.db.executeStatements(sql) {
                print("db创建失败")
            }else{
                print("db创建成功")
            }
            self.db.close()
            return true
        }else{
            print("open error")
            return false
        }
    }
}