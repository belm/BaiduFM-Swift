// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BaiduFM",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "BaiduFM",
            targets: ["BaiduFM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.10.2"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "8.11.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.12.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.2"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "6.0.0"),
    ],
    targets: [
        .target(
            name: "BaiduFM",
            dependencies: [
                "Cfmdb",
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift", condition: .when(platforms: [.iOS])),
                .product(name: "Kingfisher", package: "Kingfisher", condition: .when(platforms: [.iOS])),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "SnapKit", package: "SnapKit", condition: .when(platforms: [.iOS])),
            ],
            path: "Sources/BaiduFM",
            exclude: [
                "Info.plist",
                "MyPlayground.playground",
            ],
            resources: [
                .process("Images.xcassets"),
                .process("Base.lproj"),
                .process("en.lproj"),
                .process("zh-Hans.lproj"),
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .swiftLanguageMode(.v6),
            ]
        ),
        .target(
            name: "Cfmdb",
            path: "Sources/Libs/fmdb",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3"),
            ]
        ),
        .testTarget(
            name: "BaiduFMTests",
            dependencies: ["BaiduFM"],
            path: "Tests/BaiduFMTests",
            exclude: ["Info.plist"],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .swiftLanguageMode(.v6),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
