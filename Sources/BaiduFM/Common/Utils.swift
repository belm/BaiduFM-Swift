//
//  Utils.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/18.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation

class Utils {
    
    /**
    获取文档路径 - 获取应用程序的文档目录路径
    
    :returns: 文档路径字符串
    */
    class func documentPath() -> String{
        // 使用现代Swift API替换废弃的NSSearchPathDirectory
        return NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
    }
}