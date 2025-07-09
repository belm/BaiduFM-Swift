// swift-tools-version: 5.7
// Swift Package Manager配置文件 - BaiduFM项目依赖管理

import PackageDescription

let package = Package(
    name: "BaiduFM",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),  // 专门针对iOS 14及以上版本
        .macOS(.v10_14)  // 添加macOS支持以兼容依赖库
    ],
    products: [
        // 改为library产品，iOS应用通过Xcode构建
        .library(
            name: "BaiduFM",
            targets: ["BaiduFM"]
        ),
    ],
    dependencies: [
        // 恢复第三方依赖，使用最新稳定版本
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.6.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0"),
    ],
    targets: [
        // 改为target而不是executableTarget
        .target(
            name: "BaiduFM",
            dependencies: [
                "Cfmdb",
                // 添加第三方库依赖
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "SnapKit", package: "SnapKit"),
            ],
            path: "Sources/BaiduFM",
            exclude: [
                "Info.plist",
                "Base.lproj",
                "Images.xcassets",
                "MyPlayground.playground"
            ],
            resources: [
                .process("Images.xcassets"),
                .process("Base.lproj")
            ]
        ),
        .target(
            name: "Cfmdb",
            dependencies: [],
            path: "Sources/Libs/fmdb",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .define("SQLITE_HAS_CODEC", to: "0"),
                .unsafeFlags(["-Wno-implicit-function-declaration"])
            ]
        ),
        .testTarget(
            name: "BaiduFMTests",
            dependencies: [
                "BaiduFM"
            ],
            path: "Tests/BaiduFMTests",
            exclude: [
                "Info.plist"
            ]
        ),
    ]
) 