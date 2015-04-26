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
    @IBOutlet weak var prevButton: WKInterfaceButton!
    @IBOutlet weak var nextButton: WKInterfaceButton!
    var curPlaySongId:String? = nil
    
    @IBOutlet weak var progressLabel: WKInterfaceLabel!
    @IBOutlet weak var songTimeLabel: WKInterfaceLabel!
    
    var timer:NSTimer? = nil
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let chid = NSUserDefaults.standardUserDefaults().stringForKey("LAST_PLAY_CHANNEL_ID"){
            DataManager.shareDataManager.chid = chid
        }
    
        if DataManager.shareDataManager.songInfoList.count == 0 {
            getSongInfoList()
        }else{
            if let song = DataManager.shareDataManager.curSongInfo{
                self.playSong(song)
            }
        }
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("progresstimer:"), userInfo: nil, repeats: true)
        
        // Configure interface objects here.
    }
    
    func getSongInfoList(){
        //获取歌曲列表
        HttpRequest.getSongList(DataManager.shareDataManager.chid, callback: {(list:[String]?) -> Void in
            if let songIdList = list {
                DataManager.shareDataManager.allSongIdList = songIdList
                //获取歌曲info信息
                var songlist20 = [] + songIdList[0..<20]
                HttpRequest.getSongInfoList(songlist20, callback:{ (infolist:[SongInfo]?) -> Void in
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
        
        self.curPlaySongId = info.id
        
        //UI
        Async.main{
            
            self.progressLabel.setText("00:00")
            self.songTimeLabel.setText("00:00")
            
            self.songImage.setImageData(NSData(contentsOfURL: NSURL(string: info.songPicRadio)!)!)
            self.songNameLabel.setText(info.name + "-" + info.artistName)
            
            if DataManager.shareDataManager.curIndex == 0 {
                self.prevButton.setEnabled(false)
            }else{
                self.prevButton.setEnabled(true)
            }
            
            if DataManager.shareDataManager.curIndex >= DataManager.shareDataManager.songInfoList.count-1{
                self.nextButton.setEnabled(false)
            }else{
                self.nextButton.setEnabled(true)
            }
        }
        
        println("curIndex:\(DataManager.shareDataManager.curIndex),all:\(DataManager.shareDataManager.songInfoList.count)")
        println(Double(DataManager.shareDataManager.curIndex) / Double(DataManager.shareDataManager.songInfoList.count))
        if Double(DataManager.shareDataManager.curIndex) / Double(DataManager.shareDataManager.songInfoList.count) >= 0.75{
            self.loadMoreData()
        }
        
        //请求歌曲地址信息
        HttpRequest.getSongLink(info.id, callback: {(link:SongLink?) -> Void in
            if let songLink = link {
                DataManager.shareDataManager.curSongLink = songLink
                //播放歌曲
                DataManager.shareDataManager.mp.stop()
                var songUrl = Common.getCanPlaySongUrl(songLink.songLink)
                DataManager.shareDataManager.mp.contentURL = NSURL(string: songUrl)
                DataManager.shareDataManager.mp.prepareToPlay()
                DataManager.shareDataManager.mp.play()
                DataManager.shareDataManager.curPlayStatus = 1
                
                //显示歌曲时间
                Async.main{
                    self.songTimeLabel.setText(Common.getMinuteDisplay(songLink.time))
                }
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
        
        self.prev()
    }
    
    @IBAction func nextButtonAction() {
        
        self.next()
    }
    
    
    func prev(){
        
        DataManager.shareDataManager.curIndex--
        if let song = DataManager.shareDataManager.curSongInfo{
            self.playSong(song)
        }
    }
    
    func next(){
        
        DataManager.shareDataManager.curIndex++
        if let song = DataManager.shareDataManager.curSongInfo{
            self.playSong(song)
        }
    }
    
    @IBAction func songListAction() {
        
        self.pushControllerWithName("SongListInterfaceController", context: nil)
    }
    
    @IBAction func channelListAction() {
        self.pushControllerWithName("ChannelListInterfaceController", context: nil)
    }
    
    func loadMoreData(){
        
        if DataManager.shareDataManager.songInfoList.count >= DataManager.shareDataManager.allSongIdList.count{
            println("no more data:\(DataManager.shareDataManager.songInfoList.count),\(DataManager.shareDataManager.allSongIdList.count)")
            return
        }
        
        var curMaxCount = (Int(DataManager.shareDataManager.curIndex / 20) + 2) * 20
        println("curMaxCount:\(curMaxCount)")
        if DataManager.shareDataManager.songInfoList.count >= curMaxCount {
            return
        }
        
        var startIndex = DataManager.shareDataManager.songInfoList.count
        var endIndex = startIndex + 20
        
        if endIndex > DataManager.shareDataManager.allSongIdList.count-1 {
            endIndex = DataManager.shareDataManager.allSongIdList.count-1
        }
        
        var ids = [] + DataManager.shareDataManager.allSongIdList[startIndex..<endIndex]
        
        println("start load more data:\(startIndex),\(endIndex)")
        HttpRequest.getSongInfoList(ids, callback:{ (infolist:[SongInfo]?) -> Void in
            if let sInfoList = infolist {
                DataManager.shareDataManager.songInfoList += sInfoList
                println("load more data success,count=\(DataManager.shareDataManager.songInfoList.count)")
            }
        })

    }
    
    func progresstimer(time:NSTimer){
    
        if let link = DataManager.shareDataManager.curSongLink {
            var currentPlaybackTime = DataManager.shareDataManager.mp.currentPlaybackTime
            if currentPlaybackTime.isNaN {return}
            
            var curTime = Int(currentPlaybackTime)
            self.progressLabel.setText(Common.getMinuteDisplay(curTime))
            
            if link.time == curTime{
                self.next()
            }
        }
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        println("willActivate")
        
        if let cur = curPlaySongId {
            if let song = DataManager.shareDataManager.curSongInfo{
                if cur != song.id {
                    self.playSong(song)
                }
            }
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
