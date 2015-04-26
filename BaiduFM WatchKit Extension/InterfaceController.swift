//
//  InterfaceController.swift
//  BaiduFM WatchKit Extension
//
//  Created by lumeng on 15/4/26.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import WatchKit
import Foundation
import Async

class InterfaceController: WKInterfaceController {
    
    @IBOutlet weak var songImage: WKInterfaceImage!
    @IBOutlet weak var songNameLabel: WKInterfaceLabel!

    @IBOutlet weak var playButton: WKInterfaceButton!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if DataManager.shareDataManager.songInfoList.count == 0 {
            getSongInfoList()
        }else{
            if let song = DataManager.shareDataManager.curSongInfo{
                self.playSong(song)
            }
        }
        
        // Configure interface objects here.
    }
    
    func getSongInfoList(){
        //获取歌曲列表
        HttpRequest.getSongList(DataManager.shareDataManager.chid, callback: {(list:[String]?) -> Void in
            if let songIdList = list {
                //获取歌曲info信息
                HttpRequest.getSongInfoList(songIdList, callback:{ (infolist:[SongInfo]?) -> Void in
                    if let sInfoList = infolist {
                        DataManager.shareDataManager.songInfoList = sInfoList
                        DataManager.shareDataManager.curIndex = 0
                        if let song = DataManager.shareDataManager.curSongInfo{
                            self.playSong(song)
                        }
                    }
                })
            }
        })
    }
    
    func playSong(info:SongInfo){
        //UI
        Async.main{
            self.songImage.setImageData(NSData(contentsOfURL: NSURL(string: info.songPicRadio)!)!)
            self.songNameLabel.setText(info.name + "-" + info.artistName)
        }
        
        //请求歌曲地址信息
        HttpRequest.getSongLink(info.id, callback: {(link:SongLink?) -> Void in
            if let songLink = link {
                //播放歌曲
                DataManager.shareDataManager.mp.stop()
                var songUrl = Common.getCanPlaySongUrl(songLink.songLink)
                DataManager.shareDataManager.mp.contentURL = NSURL(string: songUrl)
                DataManager.shareDataManager.mp.prepareToPlay()
                DataManager.shareDataManager.mp.play()
                DataManager.shareDataManager.curPlayStatus = 1
            }
        })
    }
    
    @IBAction func playButtonAction() {
        
        if DataManager.shareDataManager.curPlayStatus == 1 {
            DataManager.shareDataManager.mp.pause()
            DataManager.shareDataManager.curPlayStatus = 2
            self.playButton.setBackgroundImage(UIImage(named: "btn_play"))
        }else{
            DataManager.shareDataManager.mp.play()
            DataManager.shareDataManager.curPlayStatus = 1
            self.playButton.setBackgroundImage(UIImage(named: "btn_pause"))
        }
    }
    
    @IBAction func prevButtonAction() {
        
        DataManager.shareDataManager.curIndex--
        
        if let song = DataManager.shareDataManager.curSongInfo{
            self.playSong(song)
        }
    }
    
    @IBAction func nextButtonAction() {
        
        DataManager.shareDataManager.curIndex++
        
        if let song = DataManager.shareDataManager.curSongInfo{
            self.playSong(song)
        }
    }
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
