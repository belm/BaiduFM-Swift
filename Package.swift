// swift-tools-version: 5.7
// Swift Package Manager配置文件 - BaiduFM项目依赖管理

import PackageDescription

let package = Package(
    name: "BaiduFM",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "BaiduFM",
            targets: ["BaiduFM"]
        ),
    ],
    dependencies: [
        // 网络请求库 - 现代化的HTTP客户端
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // JSON解析库 - Swift JSON处理
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        
        // 响应式编程框架 - RxSwift生态系统
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.6.0"),
        
        // 图片缓存库 - 高性能图片加载和缓存
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        
        // AutoLayout DSL - 简化约束编写
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0"),
        
        // SQLite数据库ORM - 类型安全的数据库操作
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.0"),
        
        // 异步编程库 - 简化异步操作
        .package(url: "https://github.com/duemunk/Async.git", from: "2.0.0"),
        
        // 下拉刷新库 - 现代化的刷新组件
        .package(url: "https://github.com/CoderMJLee/MJRefresh.git", from: "3.7.0"),
        
        // 文字动画效果库 - 酷炫的文字变换动画
        .package(url: "https://github.com/lexrus/LTMorphingLabel.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "BaiduFM",
            dependencies: [
                "Alamofire",
                "SwiftyJSON",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                "Kingfisher",
                "SnapKit",
                .product(name: "SQLite", package: "SQLite.swift"),
                "Async",
                "MJRefresh",
                "LTMorphingLabel"
            ]
        ),
        .testTarget(
            name: "BaiduFMTests",
            dependencies: [
                "BaiduFM",
                .product(name: "RxTest", package: "RxSwift"),
                .product(name: "RxBlocking", package: "RxSwift")
            ]
        ),
    ]
) 