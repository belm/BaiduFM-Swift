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
    
    class func getChannelList(callback:[Channel]?->Void) -> Void{
        
        var channelList:[Channel]? = nil
        
        Alamofire.request(.GET, http_channel_list_url).responseJSON{ (_, _, json, error) -> Void in
            if error == nil && json != nil {
                
                var data = JSON(json!)
                var list = data["channel_list"]
                channelList = []
                for (index:String, subJson:JSON) in list {
                    
                    let id = subJson["channel_id"].stringValue
                    let name = subJson["channel_name"].stringValue
                    let order = subJson["channel_order"].int
                    let cate_id = subJson["cate_id"].stringValue
                    let cate = subJson["cate"].stringValue
                    let cate_order = subJson["cate_order"].int
                    let pv_order = subJson["pv_order"].int
                    
                    var channel = Channel(id: id, name: name, order: order!, cate_id: cate_id, cate: cate, cate_order: cate_order!, pv_order: pv_order!)
                    channelList?.append(channel)
                }
                callback(channelList)
            }else{
                callback(nil)
            }
        }
    }
    
    class func getSongList(ch_name:String, callback:[String]?->Void)->Void{
        
        var songList:[String]? = nil
        var url = http_song_list_url + ch_name
       // println(url)
        Alamofire.request(.GET, url).responseJSON{ (_, _, json, error) -> Void in
            if error == nil && json != nil {
                //println(json)
                var data = JSON(json!)
                var list = data["list"]
                songList = []
                for (index:String, subJson:JSON) in list {
                    let id = subJson["id"].stringValue
                    songList?.append(id)
                }
                callback(songList)
            }else{
                callback(nil)
            }
        }
    }
    
    class func getSongInfoList(chidArray:[String], callback:[SongInfo]?->Void ){
        
        var chids = join(",", chidArray)
        
        let params = ["songIds":chids]
        
        Alamofire.request(.POST, http_song_info, parameters: params).responseJSON{ (_, _, json, error) -> Void in
            if error == nil && json != nil {
                var data = JSON(json!)
                
                var lists = data["data"]["songList"]
                
                var ret:[SongInfo] = []
                
                for (index:String, list:JSON) in lists {
                    
                    let id = list["songId"].stringValue
                    let name = list["songName"].stringValue
                    let artistId = list["artistId"].stringValue
                    let artistName = list["artistName"].stringValue
                    let albumId = list["albumId"].int
                    let albumName = list["albumName"].stringValue
                    let songPicSmall = list["songPicSmall"].stringValue
                    let songPicBig = list["songPicBig"].stringValue
                    let songPicRadio = list["songPicRadio"].stringValue
                    let allRate = list["allRate"].stringValue
                    
                    var songInfo = SongInfo(id: id, name: name, artistId: artistId, artistName: artistName, albumId: albumId!, albumName: albumName, songPicSmall: songPicSmall, songPicBig: songPicBig, songPicRadio: songPicRadio, allRate: allRate)
                    ret.append(songInfo)
                }
                callback(ret)
            }else{
                callback(nil)
            }
        }
    }
    
    class func getSongLinkList(chidArray:[String], callback:[SongLink]?->Void ) {
    
        var chids = join(",", chidArray)
        
        let params = ["songIds":chids]
        
        Alamofire.request(.POST, http_song_link, parameters: params).responseJSON{ (_, _, json, error) -> Void in
            if error == nil && json != nil {
                var data = JSON(json!)
                var lists = data["data"]["songList"]
                
                var ret:[SongLink] = []
                
                for (index:String, list:JSON) in lists {
                    
                    let id = list["songId"].stringValue
                    let name = list["songName"].stringValue
                    let lrcLink = list["lrcLink"].stringValue
                    let linkCode = list["linkCode"].int
                    let link = list["songLink"].stringValue
                    let format = list["format"].stringValue
                    let time = list["time"].int
                    let size = list["size"].int
                    let rate = list["rate"].int
                    
                    var t = 0, s = 0, r = 0
                    if time != nil {
                        t = time!
                    }
                    
                    if size != nil {
                        s = size!
                    }
                    
                    if rate != nil {
                        r = rate!
                    }
                    
                    var songLink = SongLink(id: id, name: name, lrcLink: lrcLink, linkCode: linkCode!, songLink: link, format: format, time: t, size: s, rate: r)
                    ret.append(songLink)
                }
                callback(ret)
            }else{
                callback(nil)
            }
        }
    }
    
    class func getSongLink(songid:String, callback:SongLink?->Void ) {
    
        let params = ["songIds":songid]
        
        Alamofire.request(.POST, http_song_link, parameters: params).responseJSON{ (_, _, json, error) -> Void in
            if error == nil && json != nil {
                var data = JSON(json!)
                var lists = data["data"]["songList"]
                
                var ret:[SongLink] = []
                
                for (index:String, list:JSON) in lists {
                    
                    let id = list["songId"].stringValue
                    let name = list["songName"].stringValue
                    let lrcLink = list["lrcLink"].stringValue
                    let linkCode = list["linkCode"].int
                    let link = list["songLink"].stringValue
                    let format = list["format"].stringValue
                    let time = list["time"].int
                    let size = list["size"].int
                    let rate = list["rate"].int
                    
                    var t = 0, s = 0, r = 0
                    if time != nil {
                        t = time!
                    }
                    
                    if size != nil {
                        s = size!
                    }
                    
                    if rate != nil {
                        r = rate!
                    }
                    
                    var songLink = SongLink(id: id, name: name, lrcLink: lrcLink, linkCode: linkCode!, songLink: link, format: format, time: t, size: s, rate: r)
                    ret.append(songLink)
                }
                if ret.count == 1 {
                    callback(ret[0])
                }else{
                    callback(nil)
                }
            }else{
                callback(nil)
            }
        }
    }
    
    class func getLrc(lrcUrl:String, callback:String?->Void) ->Void{
        
        let url = http_song_lrc + lrcUrl
        Alamofire.request(.GET, url).responseString(encoding: NSUTF8StringEncoding){ (_, _, string, error) -> Void in
            
            if error == nil {
                callback(string)
            }else{
                callback(nil)
            }
        }
    }
    
    class func downloadFile(songURL:String, musicPath:String, filePath:()->Void){
        
        var canPlaySongURL = Common.getCanPlaySongUrl(songURL)
        
        print("开始下载\(songURL)")
        Alamofire.download(Method.GET, canPlaySongURL, { (temporaryURL, response) in
            let url = NSURL(fileURLWithPath: musicPath)!
            return url
        }).response { (request, response, _, error) -> Void in
            filePath()
        }
    }
    
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