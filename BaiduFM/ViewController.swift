//
//  ViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import MediaPlayer
import Async
import LTMorphingLabel

class ViewController: UIViewController {

    @IBOutlet weak var nameLabel: LTMorphingLabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var imgView: RoundImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    
    @IBOutlet weak var songTimeLengthLabel: UILabel!
    
    @IBOutlet weak var songTimePlayLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var playButton: UIButton!
    
    var timer:NSTimer? = nil
    var currentChannel = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.nameLabel.morphingEffect = .Fall
        
        var storeChannel = NSUserDefaults.standardUserDefaults().valueForKey("LAST_PLAY_CHANNEL_ID") as? String
        if storeChannel != nil {
            DataCenter.shareDataCenter.currentChannel = storeChannel!
        }else{
            storeChannel = DataCenter.shareDataCenter.currentChannel
        }
        
        var storeChannelName = NSUserDefaults.standardUserDefaults().valueForKey("LAST_PLAY_CHANNEL_NAME") as? String
        if storeChannelName == nil {
            storeChannelName = DataCenter.shareDataCenter.currentChannelName
        }
        
        self.navigationItem.title = storeChannelName
        
        self.currentChannel = storeChannel!
        
        if DataCenter.shareDataCenter.currentAllSongId.count == 0{
            println("load data")
            HttpRequest.getSongList(self.currentChannel, callback: { (list) -> Void in
                if let songlist = list {
                    DataCenter.shareDataCenter.currentAllSongId = list!
                    self.loadSongData()
                }else{
                    var alert = UIAlertView(title: "提示", message: "请连接网络", delegate: nil, cancelButtonTitle: "确定")
                    alert.show()
                }
            })
        }else{
            self.loadSongData()
        }
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("progresstimer:"), userInfo: nil, repeats: true)
        
        //从后台激活通知
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appDidBecomeActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        println("viewDidAppear")
        self.imgView.rotation()
    }
    
    func appDidBecomeActive(){
        println("appDidBecomeActive")
         self.imgView.rotation()
    }
    
    func progresstimer(time:NSTimer){
        
        //println("progresstimer")
        if let link = DataCenter.shareDataCenter.curPlaySongLink {
            var currentPlaybackTime = DataCenter.shareDataCenter.mp.currentPlaybackTime
            
            if currentPlaybackTime.isNaN {return}
            
            //println(currentPlaybackTime)
           
            self.progressView.progress = Float(currentPlaybackTime/Double(link.time))
            //println(self.progressView.progress)
            self.songTimePlayLabel.text = Common.getMinuteDisplay(Int(currentPlaybackTime))
            
            var len = (Int)(count(self.txtView.text)/link.time)
            
            self.txtView.scrollRangeToVisible(NSRange(location: 80 + len*Int(currentPlaybackTime), length: 15))
            
            if self.progressView.progress == 1.0 {
                self.progressView.progress = 0
                self.next()
            }
            
        }
    }
    
    func loadSongData(){
        
        if DataCenter.shareDataCenter.curShowAllSongInfo.count == 0 {
            HttpRequest.getSongInfoList(DataCenter.shareDataCenter.curShowAllSongId, callback: { (info) -> Void in
                DataCenter.shareDataCenter.curShowAllSongInfo = info!
                
                HttpRequest.getSongLinkList(DataCenter.shareDataCenter.curShowAllSongId, callback: { (link) -> Void in
                    DataCenter.shareDataCenter.curShowAllSongLink = link!
                    self.start(0)
                })
            })
        }else{
            self.start(DataCenter.shareDataCenter.curPlayIndex)
        }
    }
    
    func start(index:Int){
        DataCenter.shareDataCenter.curPlayIndex = index
       // println(DataCenter.shareDataCenter.curPlayIndex)
        Async.main{
            self.showInfo()
            self.showLink()
            self.addRecentSong()
        }
    }
    
    func showInfo(){
        
        var info = DataCenter.shareDataCenter.curPlaySongInfo
        if info != nil {
            var showImg = Common.getIndexPageImage(info!)
            self.imgView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: showImg)!)!)
            self.nameLabel.text = info!.name
            self.artistLabel.text = "-" + info!.artistName + "-"
            self.albumLabel.text = info!.albumName
            
            self.imgView.rotation()
            
            self.showNowPlay(info!)
        }
    }
    
    func showLink(){
        
        var link = DataCenter.shareDataCenter.curPlaySongLink
        if link != nil {
            DataCenter.shareDataCenter.mp.stop()
            var songUrl = Common.getCanPlaySongUrl(link!.songLink)
            DataCenter.shareDataCenter.mp.contentURL = NSURL(string: songUrl)
            DataCenter.shareDataCenter.mp.prepareToPlay()
            DataCenter.shareDataCenter.mp.play()
            DataCenter.shareDataCenter.curPlayStatus = 1
            
            self.playButton.setImage(UIImage(named: "player_btn_pause_normal"), forState: UIControlState.Normal)
            
            self.songTimeLengthLabel?.text = Common.getMinuteDisplay(link!.time)
            //\\[\\d{2}:\\d{2}\\.\\d{2}\\]
            HttpRequest.getLrc(link!.lrcLink, callback: { lrc -> Void in
                var lrcAfter:String? = Common.replaceString("\\[[\\w|\\.|\\:|\\-]*\\]", replace: lrc!, place: "")
                if let lrcDis = lrcAfter {
                    
                    if lrcDis.hasPrefix("<!DOCTYPE"){
                        self.txtView.text = "暂无歌词"
                    }else{
                        self.txtView.text = lrcDis
                    }
                    
                }
                
            })
        }
    }
    
    //添加最近播放
    func addRecentSong(){
        
        var info = DataCenter.shareDataCenter.curPlaySongInfo
        var link = DataCenter.shareDataCenter.curPlaySongLink
        
        if DataCenter.shareDataCenter.dbSongList.insert(info!, link: link!){
            println("\(info!.id)添加最近播放成功")
        }else{
            println("\(info!.id)添加最近播放失败")
        }
    }
    
    @IBAction func prevSong(sender: UIButton) {
        Async.background{
            self.prev()
        }
    }
    
    
    @IBAction func nextSong(sender: UIButton) {
        Async.background{
            self.next()
        }
    }
    
    func prev(){
        DataCenter.shareDataCenter.curPlayIndex--
        if DataCenter.shareDataCenter.curPlayIndex < 0 {
            DataCenter.shareDataCenter.curPlayIndex = DataCenter.shareDataCenter.curShowAllSongId.count-1
        }
        self.start(DataCenter.shareDataCenter.curPlayIndex)
    }
    
    func next(){
        DataCenter.shareDataCenter.curPlayIndex++
        if DataCenter.shareDataCenter.curPlayIndex > DataCenter.shareDataCenter.curShowAllSongId.count{
            DataCenter.shareDataCenter.curPlayIndex = 0
        }
        self.start(DataCenter.shareDataCenter.curPlayIndex)
    }
    
    //锁屏显示歌曲专辑信息
    func showNowPlay(info:SongInfo){
    
        //var showImg = Common.getIndexPageImage(info)
        var img = UIImage(data: NSData(contentsOfURL: NSURL(string: info.songPicRadio)!)!)
        var item = MPMediaItemArtwork(image: img)
        
        var dic:[NSObject : AnyObject] = [:]
        dic[MPMediaItemPropertyTitle] = info.name
        dic[MPMediaItemPropertyArtist] = info.artistName
        dic[MPMediaItemPropertyAlbumTitle] = info.albumName
        dic[MPMediaItemPropertyArtwork] = item
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = dic
    }
    
    //接受锁屏事件
    override func remoteControlReceivedWithEvent(event: UIEvent) {
        
        if event.type == UIEventType.RemoteControl{
            switch event.subtype {
                case UIEventSubtype.RemoteControlPlay:
                    DataCenter.shareDataCenter.mp.play()
                case UIEventSubtype.RemoteControlPause:
                    DataCenter.shareDataCenter.mp.pause()
                case UIEventSubtype.RemoteControlTogglePlayPause:
                    self.togglePlayPause()
                case UIEventSubtype.RemoteControlPreviousTrack:
                    self.prev()
                case UIEventSubtype.RemoteControlNextTrack:
                    self.next()
                default:break
            }
        }
    }
    
    func togglePlayPause(){
        self.changePlayStatus(self.playButton);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func changePlayStatus(sender: UIButton) {
        
        if DataCenter.shareDataCenter.curPlayStatus == 1 {
            DataCenter.shareDataCenter.curPlayStatus = 2
            DataCenter.shareDataCenter.mp.pause()
            self.playButton.setImage(UIImage(named: "player_btn_play_normal"), forState: UIControlState.Normal)
            self.imgView.layer.removeAllAnimations()
        }else{
            DataCenter.shareDataCenter.curPlayStatus = 1
            DataCenter.shareDataCenter.mp.play()
            self.playButton.setImage(UIImage(named: "player_btn_pause_normal"), forState: UIControlState.Normal)
            self.imgView.rotation()
        }
    }
    
    @IBAction func downloadSong(sender: UIButton) {
        
        var info = DataCenter.shareDataCenter.curPlaySongLink

        if let song = info {
            
            HttpRequest.downloadFile(song.songLink, dest: "")
            
            if DataCenter.shareDataCenter.dbSongList.updateDownloadStatus(song.id){
                println("\(song.id)下载成功")
            }else{
                println("\(song.id)下载失败")
            }
        }
    }
    
    @IBAction func likeSong(sender: UIButton) {
        
        var info = DataCenter.shareDataCenter.curPlaySongInfo
        
        if let song = info {
            if DataCenter.shareDataCenter.dbSongList.updateLikeStatus(song.id, status: 1){
                println("\(song.id)收藏成功")
            }else{
                println("\(song.id)收藏失败")
            }
        }
    }

}

