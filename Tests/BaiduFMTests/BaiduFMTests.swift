//
//  BaiduFmTests.swift
//  BaiduFmTests
//
//  Created by lumeng on 15/4/26.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import XCTest

/// 百度FM应用的单元测试类
class BaiduFmTests: XCTestCase {
    
    /// 测试前的准备工作
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    /// 测试后的清理工作
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    /// 示例功能测试
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    /// 性能测试示例 - 使用现代化的measure API
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
