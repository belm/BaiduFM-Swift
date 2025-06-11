//
//  HttpRequest.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class HttpRequest {
    
    // Legacy closure-based APIs retained for compatibility, now implemented with Alamofire 5
    // =====================================================
    class func getChannelList(_ callback: @escaping ([Channel]?) -> Void) {
        AF.request(http_channel_list_url, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let list = json["channel_list"].arrayValue
                    let channels: [Channel] = list.compactMap { subJson in
                        let id = subJson["channel_id"].stringValue
                        let name = subJson["channel_name"].stringValue
                        let order = subJson["channel_order"].intValue
                        let cate_id = subJson["cate_id"].stringValue
                        let cate = subJson["cate"].stringValue
                        let cate_order = subJson["cate_order"].intValue
                        let pv_order = subJson["pv_order"].intValue
                        return Channel(id: id, name: name, order: order, cate_id: cate_id, cate: cate, cate_order: cate_order, pv_order: pv_order)
                    }
                    callback(channels)
                case .failure:
                    callback(nil)
                }
            }
    }

    class func getSongList(ch_name: String, callback: @escaping ([String]?) -> Void) {
        let url = http_song_list_url + ch_name
        AF.request(url, method: .get)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    let list = json["list"].arrayValue
                    let songIds = list.compactMap { $0["id"].string }
                    callback(songIds)
                case .failure:
                    callback(nil)
                }
            }
    }

    class func getSongInfoList(chidArray: [String], callback: @escaping ([SongInfo]?) -> Void) {
        let chids = chidArray.joined(separator: ",")
        let params = ["songIds": chids]
        AF.request(http_song_info, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let lists = JSON(value)["data"]["songList"].arrayValue
                    let infos: [SongInfo] = lists.map { list in
                        SongInfo(id: list["songId"].stringValue,
                                 name: list["songName"].stringValue,
                                 artistId: list["artistId"].stringValue,
                                 artistName: list["artistName"].stringValue,
                                 albumId: list["albumId"].intValue,
                                 albumName: list["albumName"].stringValue,
                                 songPicSmall: list["songPicSmall"].stringValue,
                                 songPicBig: list["songPicBig"].stringValue,
                                 songPicRadio: list["songPicRadio"].stringValue,
                                 allRate: list["allRate"].stringValue)
                    }
                    callback(infos)
                case .failure:
                    callback(nil)
                }
            }
    }

    class func getSongLinkList(chidArray: [String], callback: @escaping ([SongLink]?) -> Void) {
        let chids = chidArray.joined(separator: ",")
        let params = ["songIds": chids]
        AF.request(http_song_link, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let lists = JSON(value)["data"]["songList"].arrayValue
                    let links: [SongLink] = lists.map { list in
                        SongLink(id: list["songId"].stringValue,
                                 name: list["songName"].stringValue,
                                 lrcLink: list["lrcLink"].stringValue,
                                 linkCode: list["linkCode"].intValue,
                                 songLink: list["songLink"].stringValue,
                                 format: list["format"].stringValue,
                                 time: list["time"].intValue,
                                 size: list["size"].intValue,
                                 rate: list["rate"].intValue)
                    }
                    callback(links)
                case .failure:
                    callback(nil)
                }
            }
    }

    class func getSongLink(songid: String, callback: @escaping (SongLink?) -> Void) {
        let params = ["songIds": songid]
        AF.request(http_song_link, method: .post, parameters: params)
            .validate()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let lists = JSON(value)["data"]["songList"].arrayValue
                    let link = lists.first.flatMap { list -> SongLink in
                        SongLink(id: list["songId"].stringValue,
                                 name: list["songName"].stringValue,
                                 lrcLink: list["lrcLink"].stringValue,
                                 linkCode: list["linkCode"].intValue,
                                 songLink: list["songLink"].stringValue,
                                 format: list["format"].stringValue,
                                 time: list["time"].intValue,
                                 size: list["size"].intValue,
                                 rate: list["rate"].intValue)
                    }
                    callback(link)
                case .failure:
                    callback(nil)
                }
            }
    }

    class func getLrc(lrcUrl: String, callback: @escaping (String?) -> Void) {
        let url = http_song_lrc + lrcUrl
        AF.request(url, method: .get)
            .validate()
            .responseString { response in
                switch response.result {
                case .success(let lrcStr):
                    callback(lrcStr)
                case .failure:
                    callback(nil)
                }
            }
    }

    class func downloadFile(songURL: String, musicPath: String, filePath: @escaping () -> Void) {
        let canPlaySongURL = Common.getCanPlaySongUrl(url: songURL)
        guard let destinationURL = URL(string: canPlaySongURL) else { return }
        let destination: DownloadRequest.Destination = { _, _ in
            return (URL(fileURLWithPath: musicPath), [.removePreviousFile, .createIntermediateDirectories])
        }
        AF.download(destinationURL, to: destination)
            .validate()
            .response { _ in
                filePath()
            }
    }
    // =====================================================
    
    // MARK: - Modern Async/Await API
    
    enum NetworkError: Error {
        case invalidURL
        case requestFailed(Error?)
        case noData
        case jsonParsingFailed
    }
    
    @available(iOS 13.0, *)
    class func getSongListAsync(ch_name: String) async throws -> [String] {
        let urlString = http_song_list_url + ch_name
        
        let data = try await AF.request(urlString).serializingData().value
        
        let jsonObj = try JSON(data: data)
        guard let list = jsonObj["list"].array else {
            throw NetworkError.jsonParsingFailed
        }
        
        let songList = list.compactMap { $0["id"].string }
        return songList
    }

    @available(iOS 13.0, *)
    class func getSongInfoListAsync(chidArray: [String]) async throws -> [SongInfo] {
        let chids = chidArray.joined(separator: ",")
        let params = ["songIds": chids]
        
        let data = try await AF.request(http_song_info, method: .post, parameters: params).serializingData().value
        
        let jsonObj = try JSON(data: data)
        guard let lists = jsonObj["data"]["songList"].array else {
            throw NetworkError.jsonParsingFailed
        }
        
        let songInfoList = lists.map { list -> SongInfo in
            let id = list["songId"].stringValue
            let name = list["songName"].stringValue
            let artistId = list["artistId"].stringValue
            let artistName = list["artistName"].stringValue
            let albumId = list["albumId"].intValue
            let albumName = list["albumName"].stringValue
            let songPicSmall = list["songPicSmall"].stringValue
            let songPicBig = list["songPicBig"].stringValue
            let songPicRadio = list["songPicRadio"].stringValue
            let allRate = list["allRate"].stringValue
            
            return SongInfo(id: id, name: name, artistId: artistId, artistName: artistName, albumId: albumId, albumName: albumName, songPicSmall: songPicSmall, songPicBig: songPicBig, songPicRadio: songPicRadio, allRate: allRate)
        }
        
        return songInfoList
    }

    @available(iOS 13.0, *)
    class func getSongLinkAsync(songid: String) async throws -> SongLink {
        let params = ["songIds": songid]
        
        let data = try await AF.request(http_song_link, method: .post, parameters: params).serializingData().value
        
        let jsonObj = try JSON(data: data)
        guard let list = jsonObj["data"]["songList"].array?.first else {
            throw NetworkError.jsonParsingFailed
        }
        
        let id = list["songId"].stringValue
        let name = list["songName"].stringValue
        let lrcLink = list["lrcLink"].stringValue
        let linkCode = list["linkCode"].intValue
        let link = list["songLink"].stringValue
        let format = list["format"].stringValue
        let time = list["time"].intValue
        let size = list["size"].intValue
        let rate = list["rate"].intValue
        
        return SongLink(id: id, name: name, lrcLink: lrcLink, linkCode: linkCode, songLink: link, format: format, time: time, size: size, rate: rate)
    }

    @available(iOS 13.0, *)
    class func getLrcAsync(lrcUrl: String) async throws -> String {
        let url = http_song_lrc + lrcUrl
        
        let response = await AF.request(url).serializingString(encoding: .utf8).response
        
        switch response.result {
        case .success(let lrcString):
            return lrcString
        case .failure(let error):
            throw error
        }
    }
}