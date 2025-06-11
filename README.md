# BaiduFM-Swift

**Language**: [English](#) | [中文](./README-zh.md)

[![](http://img.shields.io/badge/build-passing-4BC51D.svg)]()
[![](http://img.shields.io/badge/OS%20X-10.10.3-blue.svg)]() 
[![](http://img.shields.io/badge/xcode-6.3-blue.svg)]()
[![](http://img.shields.io/badge/iOS-8.0%2B-blue.svg)]() 
[![](http://img.shields.io/badge/Swift-1.2-blue.svg)]() 

A Baidu FM client implemented in Swift, based on the latest Xcode 6.3 + Swift 1.2. This project was initially focused on implementing basic functionality, and the code may be rough in some areas. I plan to refactor and optimize it when time permits.

## API Disclaimer
- This app uses Baidu FM's non-public API. All music copyrights belong to Baidu.

## Features

- Apple Watch support (synchronized lyrics display)
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
- [Async](https://github.com/duemunk/Async) - Asynchronous programming
- [MJRefresh](https://github.com/CoderMJLee/MJRefresh) - Pull-to-refresh
- [LTMorphingLabel](https://github.com/lexrus/LTMorphingLabel) - Text animation effects
- [Kingfisher](https://github.com/onevcat/Kingfisher) - Image caching and downloading

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
- Online MP3 playback using MPMoviePlayerController
- NSNotificationCenter for data passing

## TODO Features

- Replace music playback with AVAudioPlayer
- Enhanced Apple Watch support

## Contact
- [QQ Email](mailto:belm@vip.qq.com)
- [Weibo](http://weibo.com/belmeng)

[![Powered by DartNode](https://dartnode.com/branding/DN-Open-Source-sm.png)](https://dartnode.com "Powered by DartNode - Free VPS for Open Source")
