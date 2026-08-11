//
//  NetworkManager.swift
//  BaiduFM
//
//  Secure network access for the configured content provider.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift

// MARK: - 网络错误类型
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case connectionError
    case insecureTransport
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return L10n.invalidURL
        case .noData:
            return L10n.noResponseData
        case .decodingError:
            return L10n.decodingFailed
        case .serverError(let message):
            return String(format: L10n.serverErrorFormat, message)
        case .connectionError:
            return L10n.connectionFailed
        case .insecureTransport:
            return L10n.insecureConnectionBlocked
        }
    }
}

// MARK: - 网络管理器
final class NetworkManager {
    
    // MARK: - 单例
    static let shared = NetworkManager()
    
    // MARK: - 私有属性
    private let session: Session
    private let configuration: APIConfiguration
    
    // MARK: - 初始化
    private init(configuration: APIConfiguration = .resolved()) {
        self.configuration = configuration

        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 30
        sessionConfiguration.timeoutIntervalForResource = 60
        sessionConfiguration.waitsForConnectivity = true
        
        // 创建自定义会话
        self.session = Session(configuration: sessionConfiguration)
    }
    
    // MARK: - JSON响应请求方法
    private func requestJSON(
        url: URL,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil
    ) -> Observable<JSON> {
        
        return Observable.create { observer in
            let observer = RxObserverBox(observer)
            let request = self.session.request(
                url,
                method: method,
                parameters: parameters
            )
            .validate()
            .responseData { response in
                
                switch response.result {
                case .success(let data):
                    do {
                        observer.onNext(try JSON(data: data))
                        observer.onCompleted()
                    } catch {
                        observer.onError(NetworkError.decodingError)
                    }
                    
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 400...499:
                            observer.onError(NetworkError.serverError(String(format: L10n.clientStatusFormat, statusCode)))
                        case 500...599:
                            observer.onError(NetworkError.serverError(String(format: L10n.serverStatusFormat, statusCode)))
                        default:
                            observer.onError(NetworkError.connectionError)
                        }
                    } else {
                        print("Network request failed: \(error.localizedDescription)")
                        observer.onError(NetworkError.connectionError)
                    }
                }
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
}

// MARK: - 百度FM API接口
extension NetworkManager {
    func secureContentURL(from value: String) -> URL? {
        configuration.secureContentURL(from: value)
    }

    private func apiURL(queryItems: [URLQueryItem]) -> Observable<URL> {
        do {
            return .just(try configuration.endpoint(queryItems: queryItems))
        } catch {
            return .error(error)
        }
    }
    
    // MARK: - 获取频道列表
    func getChannelList() -> Observable<[Channel]> {
        return apiURL(queryItems: [URLQueryItem(name: "tn", value: "channellist")])
            .flatMapLatest { [weak self] url -> Observable<JSON> in
                guard let self else { return .empty() }
                return self.requestJSON(url: url)
            }
            .map { json -> [Channel] in
                let channelArray = json["channel_list"].arrayValue
                return channelArray.compactMap { channelJSON in
                    Channel(
                        id: channelJSON["channel_id"].stringValue,
                        name: channelJSON["channel_name"].stringValue,
                        order: channelJSON["channel_order"].intValue,
                        cate_id: channelJSON["cate_id"].stringValue,
                        cate: channelJSON["cate"].stringValue,
                        cate_order: channelJSON["cate_order"].intValue,
                        pv_order: channelJSON["pv_order"].intValue
                    )
                }
            }
    }
    
    // MARK: - 获取歌曲列表
    func getSongList(channelId: String) -> Observable<[String]> {
        return apiURL(queryItems: [
            URLQueryItem(name: "tn", value: "playlist"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "id", value: channelId),
        ])
            .flatMapLatest { [weak self] url -> Observable<JSON> in
                guard let self else { return .empty() }
                return self.requestJSON(url: url)
            }
            .map { json -> [String] in
                let songArray = json["list"].arrayValue
                return songArray.map { $0["id"].stringValue }
            }
    }
    
    // MARK: - 获取歌曲详细信息
    func getSongInfo(songIds: [String]) -> Observable<[SongInfo]> {
        let idsString = songIds.joined(separator: ",")
        return apiURL(queryItems: [
            URLQueryItem(name: "tn", value: "songinfo"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "ids", value: idsString),
        ])
            .flatMapLatest { [weak self] url -> Observable<JSON> in
                guard let self else { return .empty() }
                return self.requestJSON(url: url)
            }
            .map { json -> [SongInfo] in
                let songArray = json["songinfo"].arrayValue
                return songArray.compactMap { songJSON in
                    SongInfo(
                        songId: songJSON["song_id"].stringValue,
                        name: songJSON["title"].stringValue,
                        artistName: songJSON["artist"].stringValue,
                        albumName: songJSON["album_title"].stringValue,
                        picUrl: songJSON["pic_big"].stringValue
                    )
                }
            }
    }
    
    // MARK: - 获取歌曲播放链接
    func getSongLinks(songIds: [String]) -> Observable<[SongLink]> {
        let idsString = songIds.joined(separator: ",")
        return apiURL(queryItems: [
            URLQueryItem(name: "tn", value: "songlink"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "ids", value: idsString),
        ])
            .flatMapLatest { [weak self] url -> Observable<JSON> in
                guard let self else { return .empty() }
                return self.requestJSON(url: url)
            }
            .map { json -> [SongLink] in
                let linkArray = json["songlink"].arrayValue
                return linkArray.compactMap { linkJSON in
                    SongLink(
                        songId: linkJSON["songid"].stringValue,
                        songLink: linkJSON["songlink"].stringValue,
                        lrcLink: linkJSON["lrclink"].stringValue,
                        time: linkJSON["time"].intValue,
                        format: linkJSON["format"].stringValue
                    )
                }
            }
    }
    
    // MARK: - 获取歌词内容
    func getLyrics(url: String) -> Observable<String> {
        guard let secureURL = configuration.secureContentURL(from: url) else {
            return .error(NetworkError.insecureTransport)
        }

        return requestJSON(url: secureURL)
            .map { json -> String in
                return json["lrcContent"].stringValue
            }
            .catch { _ in
                // 如果JSON解析失败，尝试直接获取文本
                return self.requestLyricsText(url: secureURL)
            }
    }
    
    // MARK: - 直接获取歌词文本
    private func requestLyricsText(url: URL) -> Observable<String> {
        return Observable.create { observer in
            let observer = RxObserverBox(observer)
            let request = self.session.request(url)
                .responseString { response in
                    switch response.result {
                    case .success(let text):
                        observer.onNext(text)
                        observer.onCompleted()
                    case .failure:
                        observer.onNext("") // 返回空字符串而不是错误
                        observer.onCompleted()
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    // MARK: - 下载音频文件
    func downloadAudio(from url: String, to destination: URL) -> Observable<Float> {
        guard let secureURL = configuration.secureContentURL(from: url) else {
            return .error(NetworkError.insecureTransport)
        }

        return Observable.create { observer in
            let observer = RxObserverBox(observer)
            let destination: DownloadRequest.Destination = { _, _ in
                return (destination, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            let request = self.session.download(secureURL, to: destination)
                .downloadProgress { progress in
                    observer.onNext(Float(progress.fractionCompleted))
                }
                .response { response in
                    if response.error == nil {
                        observer.onNext(1.0) // 下载完成
                        observer.onCompleted()
                    } else {
                        observer.onError(NetworkError.connectionError)
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
}

// MARK: - 数据模型定义
struct SongInfo: Sendable {
    let songId: String
    let name: String
    let artistName: String
    let albumName: String
    let picUrl: String
}

struct SongLink: Sendable {
    let songId: String
    let songLink: String
    let lrcLink: String
    let time: Int
    let format: String
}
