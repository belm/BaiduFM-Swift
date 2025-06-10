# BaiduFM-Swift

**语言**: [English](./README.md) | [中文](#)

[![](http://img.shields.io/badge/build-passing-4BC51D.svg)]()
[![](http://img.shields.io/badge/OS%20X-10.10.3-blue.svg)]() 
[![](http://img.shields.io/badge/xcode-6.3-blue.svg)]()
[![](http://img.shields.io/badge/iOS-8.0%2B-blue.svg)]() 
[![](http://img.shields.io/badge/Swift-1.2-blue.svg)]() 
[![CocoaPods compatible](https://img.shields.io/badge/CocoaPods-compatible-4BC51D.svg)](https://github.com/cocoapods/cocoapods)

百度FM 客户端，使用 Swift 语言实现，基于最新的 Xcode 6.3 + Swift 1.2 开发。项目初期主要专注于功能实现，代码可能在某些地方比较粗糙，后续有时间会进行重构和优化。

## API 接口声明
- 本 APP 使用百度 FM 非公开 API，音乐版权归百度所有。

## 功能特性

- 支持 Apple Watch（歌词同步显示）
- 下载歌曲到本地存储（支持删除功能）
- 收藏音乐管理（添加/取消收藏）
- 最近播放历史记录（支持清空功能）
- 下拉刷新和上拉加载更多歌曲
- 歌词自动滚动显示
- 实时播放进度显示
- 播放/暂停控制
- 上一曲/下一曲导航
- 音乐分类浏览
- 分类歌曲列表
- 后台播放支持
- 锁屏显示专辑封面和歌曲信息
- 锁屏音乐控制（上一曲/下一曲、播放/暂停）
- 收藏列表、最近播放列表、下载歌曲列表

## 项目截图

- Apple Watch 首页 ![项目截图0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_00.png?raw=true)

- Apple Watch 菜单页面 ![项目截图0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_01.png?raw=true)

- Apple Watch 歌曲列表 ![项目截图0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_02.png?raw=true)

- Apple Watch 歌曲分类选择 ![项目截图0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_AppleWatch_03.png?raw=true)

- iPhone 锁屏显示和播放控制 ![项目截图0](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_00.png?raw=true)

- iPhone 项目首页 ![项目截图1](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_01.png?raw=true)

- iPhone 音乐分类 ![项目截图2](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_02.png?raw=true)

- iPhone 歌曲列表 ![项目截图3](https://github.com/belm/BaiduFM-Swift/blob/master/ScreenShot/BaiduFM-Swift_03.png?raw=true)

## 使用说明
- 项目使用 [COCOAPODS](https://github.com/cocoapods/cocoapods) 管理第三方库，运行前请先执行 `pod install` 安装依赖库。

## 第三方库依赖

- [Alamofire](https://github.com/Alamofire/Alamofire) - 网络请求库
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - JSON 解析库
- [FMDB](https://github.com/ccgus/fmdb) - SQLite 数据库封装
- [Async](https://github.com/duemunk/Async) - 异步编程库
- [MJRefresh](https://github.com/CoderMJLee/MJRefresh) - 下拉刷新组件
- [LTMorphingLabel](https://github.com/lexrus/LTMorphingLabel) - 文字动画效果
- [Kingfisher](https://github.com/onevcat/Kingfisher) - 图片缓存和下载

## 使用的 Swift 技术点
- 网络请求处理
- JSON 数据解析
- Swift 正则表达式
- Swift 单例模式
- 下拉刷新和上拉加载（MJRefresh）
- 播放进度显示（UIProgressView）
- 歌词滚动显示（UITextView）
- 闭包（Closures）
- 属性观察器（get、set、didSet）
- 使用 MPMoviePlayerController 在线播放网络 MP3
- NSNotificationCenter 数据传递

## 待完成功能

- 使用 AVAudioPlayer 替换音乐播放
- 第三方库整合（已改用 [COCOAPODS](https://github.com/cocoapods/cocoapods) 管理）
- 增强 Apple Watch 支持

## 联系方式
- [QQ 邮箱](mailto:belm@vip.qq.com)
- [微博](http://weibo.com/belmeng)

[![Powered by DartNode](https://dartnode.com/branding/DN-Open-Source-sm.png)](https://dartnode.com "Powered by DartNode - Free VPS for Open Source") 