# BaiduFM-Swift

**语言**: [English](./README.md) | [中文](#)

[![](http://img.shields.io/badge/build-passing-4BC51D.svg)]()
[![](https://img.shields.io/badge/Swift-6.2-orange.svg)]()
[![](https://img.shields.io/badge/iOS-15.0%2B-blue.svg)]()
[![](https://img.shields.io/badge/SPM-supported-brightgreen.svg)]()

百度 FM 客户端，现已更新到 Swift 6.2、Swift Package Manager 和 iOS 15 以上版本。界面支持英语和简体中文，英语为开发语言及默认回退语言。

## 编译方式

1. 安装包含 Swift 6.2 或更高版本的 Xcode。
2. 使用 Xcode 打开 `BaiduFM.xcodeproj`，选择共享的 `BaiduFMApp` Scheme。
3. 在 `Configuration/Shared.xcconfig` 中将 `BAIDUFM_API_BASE_URL` 设置为已获授权的 HTTPS 内容服务。
4. 选择 iOS 模拟器或真机并运行 App。

也可以使用 `swift build` 验证跨平台核心代码。完整 iOS 编译需要 Xcode，因为项目使用了 UIKit、AVFoundation、Storyboard 和 Asset Catalog。

历史百度 FM 地址仅作为开发默认值保留，服务可能不可用。正式发行前必须获得 API、音频流、封面、歌词、商标及下载功能的明确授权，详见[发布检查清单](Documentation/RELEASE_CHECKLIST.md)。

## API 接口声明
- 本仓库是引用历史百度 FM 非公开 API 的开发示例。未获得相关权利人与服务提供方明确授权前，不得携带第三方内容、品牌、音频流或下载能力进行发行。

## 功能特性

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

## 第三方库依赖

- [Alamofire](https://github.com/Alamofire/Alamofire) - 网络请求库
- [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON) - JSON 解析库
- [FMDB](https://github.com/ccgus/fmdb) - SQLite 数据库封装
- [Kingfisher](https://github.com/onevcat/Kingfisher) - 图片缓存和下载
- [RxSwift](https://github.com/ReactiveX/RxSwift) - 响应式界面与状态绑定
- [SnapKit](https://github.com/SnapKit/SnapKit) - Auto Layout DSL

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
- 使用 AVPlayer 播放网络音频
- 使用类型化的 NotificationCenter 名称传递事件

## 待完成功能

- 提升百度非公开 API 发生变化时的兼容性

## 联系方式
- [QQ 邮箱](mailto:belm@vip.qq.com)
- [微博](http://weibo.com/belmeng)

[![Powered by DartNode](https://dartnode.com/branding/DN-Open-Source-sm.png)](https://dartnode.com "Powered by DartNode - Free VPS for Open Source")
