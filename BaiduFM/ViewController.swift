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
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var lengthLabel: UILabel!
    
    @IBOutlet weak var songTimeLengthLabel: UILabel!
    
    @IBOutlet weak var songTimePlayLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    
    var timer:NSTimer? = nil
    var currentChannel = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.nameLabel.morphingEffect = .Fall
        
        //背景图片模糊效果
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame.size = CGSize(width: view.frame.width, height: view.frame.height)
        self.bgImageView.addSubview(blurView)
        
        self.currentChannel = DataCenter.shareDataCenter.currentChannel
        
        if let storeChannel = NSUserDefaults.standardUserDefaults().valueForKey("LAST_PLAY_CHANNEL_ID") as? String{
            self.currentChannel = storeChannel
        }
        
        if let channelName = NSUserDefaults.standardUserDefaults().valueForKey("LAST_PLAY_CHANNEL_NAME") as? String{
            DataCenter.shareDataCenter.currentChannelName = channelName
        }
        
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
        
        //监听歌曲列表点击
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("musicListClick"), name: CHANNEL_MUSIC_LIST_CLICK_NOTIFICATION, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("otherMusicListClick:"), name: OTHER_MUSIC_LIST_CLICK_NOTIFICATION, object: nil)
        
    }
    
    deinit{
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        println("viewDidAppear")
        if !self.imgView.isAnimating() && DataCenter.shareDataCenter.curPlayStatus == 1{
            self.imgView.rotation()
        }
    }
    
    func appDidBecomeActive(){
        println("appDidBecomeActive")
        if !self.imgView.isAnimating() && DataCenter.shareDataCenter.curPlayStatus == 1{
            self.imgView.rotation()
        }
    }
    
    func musicListClick(){
        self.start(DataCenter.shareDataCenter.curPlayIndex)
    }
    
    func otherMusicListClick(notification:NSNotification){
        
        var info = notification.userInfo as! [String:AnyObject]
        var song = info["song"] as! Song
        println("\(song.name)")
        
        self.show(song.pic_url, name: song.name, artistName: song.artist, albumName: song.album, songLink: song.song_url, time: song.time, lrcLink: song.lrc_url, songId:song.sid, format:song.format)
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
                
                if info == nil {return}
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
            
            if index == 0 {
                self.prevButton.enabled = false
            }else{
                self.prevButton.enabled = true
            }
            
            if index == DataCenter.shareDataCenter.curShowAllSongId.count - 1 {
                self.nextButton.enabled = false
            }else{
                self.nextButton.enabled = true
            }
            
            var info = DataCenter.shareDataCenter.curPlaySongInfo
            var link = DataCenter.shareDataCenter.curPlaySongLink
            
            if info == nil || link == nil {return}
            
            var showImg = Common.getIndexPageImage(info!)
            
            self.show(showImg, name: info!.name, artistName: info!.artistName, albumName: info!.albumName, songLink: link!.songLink, time: link!.time, lrcLink: link!.lrcLink, songId:link!.id, format:link!.format)
        
            self.addRecentSong()
        }
    }
    
    func resetUI(){
        self.progressView.progress = 0
        self.songTimePlayLabel.text = "00:00"
        self.songTimeLengthLabel.text = "00:00"
        self.txtView.text = ""
    }
    
    func show(showImg:String,name:String,artistName:String,albumName:String,songLink:String,time:Int, lrcLink:String,songId:String,format:String){
        
        self.resetUI()
        
        self.navigationItem.title = DataCenter.shareDataCenter.currentChannelName
        
        //info
        
        self.imgView.kf_setImageWithURL(NSURL(string: showImg)!)
        //self.imgView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: showImg)!)!)
        self.nameLabel.text = name
        self.artistLabel.text = "-" + artistName + "-"
        self.albumLabel.text = albumName
        self.bgImageView.kf_setImageWithURL(NSURL(string: showImg)!)
        //self.bgImageView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: showImg)!)!)
        self.imgView.rotation()
        
        //锁屏显示
        self.showNowPlay(showImg, name: name, artistName: artistName, albumName: albumName)
        
        //link 
        DataCenter.shareDataCenter.mp.stop()
        var songUrl = Common.getCanPlaySongUrl(songLink)
        
        //如果已经下载 播放本地音乐
        var musicFile = Common.musicLocalPath(songId, format: format)
        if Common.fileIsExist(musicFile){
            println("播放本地音乐")
            DataCenter.shareDataCenter.mp.contentURL = NSURL(fileURLWithPath: musicFile)!
        }else{
            DataCenter.shareDataCenter.mp.contentURL = NSURL(string: songUrl)
        }
        
        DataCenter.shareDataCenter.mp.prepareToPlay()
        DataCenter.shareDataCenter.mp.play()
        DataCenter.shareDataCenter.curPlayStatus = 1
        
        self.playButton.setImage(UIImage(named: "player_btn_pause_normal"), forState: UIControlState.Normal)
        
        self.songTimeLengthLabel?.text = Common.getMinuteDisplay(time)
        //\\[\\d{2}:\\d{2}\\.\\d{2}\\]
        HttpRequest.getLrc(lrcLink, callback: { lrc -> Void in
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
    
    //添加最近播放
    func addRecentSong(){
        
        var info = DataCenter.shareDataCenter.curPlaySongInfo
        var link = DataCenter.shareDataCenter.curPlaySongLink
        
        if info == nil || link == nil {
            return
        }
        
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
    func showNowPlay(songPic:String,name:String,artistName:String,albumName:String){
        
        //var showImg = Common.getIndexPageImage(info)        
        var img = UIImage(data: NSData(contentsOfURL: NSURL(string: songPic)!)!)
        var item = MPMediaItemArtwork(image: img)
        
        var dic:[NSObject : AnyObject] = [:]
        dic[MPMediaItemPropertyTitle] = name
        dic[MPMediaItemPropertyArtist] = artistName
        dic[MPMediaItemPropertyAlbumTitle] = albumName
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
        
        var musicPath = Common.musicLocalPath(info!.id, format: info!.format)
        
        if Common.fileIsExist(musicPath){
            println("文件已经存在")
            return
        }
        
        if let song = info {
            HttpRequest.downloadFile(song.songLink, musicPath: musicPath, filePath: { () -> Void in
                println("下载完成\(musicPath)")
                
                if Common.fileIsExist(musicPath){
                    if DataCenter.shareDataCenter.dbSongList.updateDownloadStatus(song.id){
                        println("\(song.id)更新db成功")
                    }else{
                        println("\(song.id)更新db失败")
                    }
                }else{
                    println("\(musicPath)文件不存在")
                }
            })
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

