//
//  NetworkManager.swift
//  BaiduFM
//
//  现代化的网络请求管理器
//  使用Alamofire 5.x + RxSwift进行网络请求和响应式编程
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
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的URL地址"
        case .noData:
            return "没有返回数据"
        case .decodingError:
            return "数据解析失败"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .connectionError:
            return "网络连接失败"
        }
    }
}

// MARK: - API响应模型
struct APIResponse<T> {
    let data: T?
    let message: String?
    let code: Int
}

// MARK: - 网络管理器
class NetworkManager {
    
    // MARK: - 单例
    static let shared = NetworkManager()
    
    // MARK: - 私有属性
    private let session: Session
    private let baseURL = "http://fm.baidu.com"
    
    // MARK: - 初始化
    private init() {
        // 配置网络会话
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        // 创建自定义会话
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - 通用请求方法
    private func request<T: Decodable>(
        url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil
    ) -> Observable<T> {
        
        return Observable.create { observer in
            let request = self.session.request(
                url,
                method: method,
                parameters: parameters,
                encoding: encoding,
                headers: headers
            )
            .validate()
            .responseData { response in
                
                switch response.result {
                case .success(let data):
                    do {
                        let decodedData = try JSONDecoder().decode(T.self, from: data)
                        observer.onNext(decodedData)
                        observer.onCompleted()
                    } catch {
                        observer.onError(NetworkError.decodingError)
                    }
                    
                case .failure(let error):
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 400...499:
                            observer.onError(NetworkError.serverError("客户端错误: \(statusCode)"))
                        case 500...599:
                            observer.onError(NetworkError.serverError("服务器错误: \(statusCode)"))
                        default:
                            observer.onError(NetworkError.connectionError)
                        }
                    } else {
                        observer.onError(NetworkError.connectionError)
                    }
                }
            }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    // MARK: - JSON响应请求方法
    private func requestJSON(
        url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil
    ) -> Observable<JSON> {
        
        return Observable.create { observer in
            let request = self.session.request(
                url,
                method: method,
                parameters: parameters
            )
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    observer.onNext(json)
                    observer.onCompleted()
                    
                case .failure(let error):
                    print("网络请求失败: \(error.localizedDescription)")
                    observer.onError(NetworkError.connectionError)
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
    
    // MARK: - 获取频道列表
    func getChannelList() -> Observable<[Channel]> {
        let url = "\(baseURL)/dev/api/?tn=channellist"
        
        return requestJSON(url: url)
            .map { json -> [Channel] in
                let channelArray = json["channel_list"].arrayValue
                return channelArray.compactMap { channelJSON in
                    Channel(
                        channelId: channelJSON["channel_id"].stringValue,
                        channelName: channelJSON["channel_name"].stringValue
                    )
                }
            }
    }
    
    // MARK: - 获取歌曲列表
    func getSongList(channelId: String) -> Observable<[String]> {
        let url = "\(baseURL)/dev/api/?tn=playlist&format=json&id=\(channelId)"
        
        return requestJSON(url: url)
            .map { json -> [String] in
                let songArray = json["list"].arrayValue
                return songArray.map { $0["id"].stringValue }
            }
    }
    
    // MARK: - 获取歌曲详细信息
    func getSongInfo(songIds: [String]) -> Observable<[SongInfo]> {
        let idsString = songIds.joined(separator: ",")
        let url = "\(baseURL)/dev/api/?tn=songinfo&format=json&ids=\(idsString)"
        
        return requestJSON(url: url)
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
        let url = "\(baseURL)/dev/api/?tn=songlink&format=json&ids=\(idsString)"
        
        return requestJSON(url: url)
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
        return requestJSON(url: url)
            .map { json -> String in
                return json["lrcContent"].stringValue
            }
            .catch { _ in
                // 如果JSON解析失败，尝试直接获取文本
                return self.requestLyricsText(url: url)
            }
    }
    
    // MARK: - 直接获取歌词文本
    private func requestLyricsText(url: String) -> Observable<String> {
        return Observable.create { observer in
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
        return Observable.create { observer in
            let destination: DownloadRequest.Destination = { _, _ in
                return (destination, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            let request = self.session.download(url, to: destination)
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
struct SongInfo {
    let songId: String
    let name: String
    let artistName: String
    let albumName: String
    let picUrl: String
}

struct SongLink {
    let songId: String
    let songLink: String
    let lrcLink: String
    let time: Int
    let format: String
} 