# BaiduFM-Swift

**Language**: [English](#) | [中文](./README-zh.md)

[![](http://img.shields.io/badge/build-passing-4BC51D.svg)]()
[![](https://img.shields.io/badge/Swift-6.2-orange.svg)]()
[![](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)]()
[![](https://img.shields.io/badge/SPM-supported-brightgreen.svg)]()

A Baidu FM client modernized for Swift 6.2, Swift Package Manager, and iOS 15 or later. The UI supports English and Simplified Chinese; English is the development and fallback language.

## Build

1. Install an Xcode release that includes Swift 6.2 or later.
2. Open `BaiduFM.xcodeproj` in Xcode and select the shared `BaiduFMApp` scheme.
3. Set `BAIDUFM_API_BASE_URL` in `Configuration/Shared.xcconfig` to an authorized HTTPS content service.
4. Select an iOS Simulator or connected device and run the app.

Command-line core validation is also available with `swift build`. A complete iOS build requires Xcode because the app uses UIKit, AVFoundation, storyboards, and asset catalogs.

The historical Baidu FM endpoint is retained only as a development default and may be unavailable. Production distribution requires explicit authorization for the API, streams, artwork, lyrics, trademarks, and downloads. See [the release checklist](Documentation/RELEASE_CHECKLIST.md).

## API Disclaimer
- This repository is a development sample that references a historical, non-public Baidu FM API. It must not be distributed with third-party content, branding, streaming, or download access without explicit authorization from the relevant rights holders and service provider.

## Features

- Download songs to local storage (with delete functionality)
- Favorite music management (add/remove favorites)
- Recently played music history (with clear functionality)
- Pull-to-refresh and load more songs
- Auto-scrolling lyrics
- Real-time playback progress display
- Play/pause control
- Previous/next track navigation
- Music category browsing
- Categorized song lists
- Background playback support
- Lock screen album artwork and song info display
- Lock screen music controls (next/previous, play/pause)
- Favorites list, recently played list, and downloaded songs list

## Screenshots

- Apple Watch Home ![Screenshot 0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_00.png?raw=true)

- Apple Watch Menu ![Screenshot 0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_01.png?raw=true)

- Apple Watch Song List ![Screenshot 0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_02.png?raw=true)

- Apple Watch Category Selection ![Screenshot 0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_03.png?raw=true)

- iPhone Lock Screen Display & Controls ![Screenshot 0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_00.png?raw=true)

- iPhone Home Screen ![Screenshot 1](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_01.png?raw=true)

- iPhone Music Categories ![Screenshot 2](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_02.png?raw=true)

- iPhone Song List ![Screenshot 3](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_03.png?raw=true)

## Third-Party Libraries

- [Alamofire](https://github.com/Alamofire/Alamofire) - Networking library
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - JSON parsing
- [FMDB](https://github.com/ccgus/fmdb) - SQLite database wrapper
- [Kingfisher](https://github.com/onevcat/Kingfisher) - Image caching and downloading
- [RxSwift](https://github.com/ReactiveX/RxSwift) - Reactive UI and state binding
- [SnapKit](https://github.com/SnapKit/SnapKit) - Auto Layout DSL

## Swift Concepts Used
- Network requests
- JSON parsing
- Swift regular expressions
- Swift singleton pattern
- Pull-to-refresh & load more with MJRefresh
- Song progress with UIProgressView
- Lyrics scrolling with UITextView
- Closures
- Property observers (get, set, didSet)
- Streaming audio playback using AVPlayer
- Typed NotificationCenter names for data passing

## TODO Features

- Improve API resilience when Baidu changes its private endpoints

## Contact
- [QQ Email](mailto:belm@vip.qq.com)
- [Weibo](http://weibo.com/belmeng)

[![Powered by DartNode](https://dartnode.com/branding/DN-Open-Source-sm.png)](https://dartnode.com "Powered by DartNode - Free VPS for Open Source")
