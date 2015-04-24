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
        
        let url = "http://fm.baidu.com/dev/api/?tn=channellist&hashcode=310d03041bffd10803bc3ee8913e2726&_=1428801468750"
        Alamofire.request(.GET, url).responseJSON{ (_, _, json, error) -> Void in
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
        var url = "http://fm.baidu.com/dev/api/?tn=playlist&id=" + ch_name + "&hashcode=310d03041bffd10803bc3ee8913e2726&_=1428917601565"
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
        
        let url = "http://fm.baidu.com/data/music/songinfo"
        var chids = join(",", chidArray)
        
        let params = ["songIds":chids]
        
        Alamofire.request(.POST, url, parameters: params).responseJSON{ (_, _, json, error) -> Void in
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
        
        let url = "http://fm.baidu.com/data/music/songlink"
    
        var chids = join(",", chidArray)
        
        let params = ["songIds":chids]
        
        Alamofire.request(.POST, url, parameters: params).responseJSON{ (_, _, json, error) -> Void in
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
    
    class func getLrc(lrcUrl:String, callback:String?->Void) ->Void{
        
        //http://fm.baidu.com/data2/lrc/14881153/14881153.lrc
        
        let baseUrl = "http://fm.baidu.com"
        let url = baseUrl + lrcUrl
        Alamofire.request(.GET, url).responseString(encoding: NSUTF8StringEncoding){ (_, _, string, error) -> Void in
            
            if error == nil {
                callback(string)
            }else{
                callback(nil)
            }
        }
    }
    
    class func downloadFile(songUrl:String, filePath:(path:NSURL)->Void){
        
        
        Alamofire.download(Method.GET, songUrl, { (temporaryURL, response) in
            
            if let directoryURL = NSFileManager.defaultManager()
                .URLsForDirectory(.DocumentDirectory,
                    inDomains: .UserDomainMask)[0]
                as? NSURL {
                let pathComponent = response.suggestedFilename
                var ret = directoryURL.URLByAppendingPathComponent(pathComponent!)
                filePath(path: ret)
                return ret
            }
            filePath(path: temporaryURL)
            return temporaryURL
        })
        
        /*
        var dbDirectory = Utils.documentPath().stringByAppendingPathComponent("download")
        if !NSFileManager.defaultManager().fileExistsAtPath(dbDirectory){
            NSFileManager.defaultManager().createDirectoryAtPath(dbDirectory, withIntermediateDirectories: false, attributes: nil, error: nil)
        }
        */
        
        /*
        println(Utils.documentPath())
        
        let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)

        Alamofire.download(Method.GET, songUrl, destination)
            .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                println("bytesRead:\(bytesRead),totalBytesRead:\(totalBytesRead),totalBytesExpectedToRead:\(totalBytesRead)")
            }
            .response { (request, response, _, error) in
                println(response)
            }
        */
    }
}