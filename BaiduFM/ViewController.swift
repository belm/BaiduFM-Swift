//
//  ViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/12.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
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
                }
            })
        }else{
            self.loadSongData()
        }
        
        self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("progresstimer:"), userInfo: nil, repeats: true)
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
        self.showInfo()
        self.showLink()
    }
    
    func showInfo(){
        
        var info = DataCenter.shareDataCenter.curPlaySongInfo
        if info != nil {
            var showImg = Common.getIndexPageImage(info!)
            self.imgView.image = UIImage(data: NSData(contentsOfURL: NSURL(string: showImg)!)!)
            self.nameLabel.text = info!.name
            self.artistLabel.text = "-" + info!.artistName + "-"
            self.albumLabel.text = info!.albumName
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
    
    
    @IBAction func prevSong(sender: UIButton) {
        
        DataCenter.shareDataCenter.curPlayIndex--
        if DataCenter.shareDataCenter.curPlayIndex < 0 {
            DataCenter.shareDataCenter.curPlayIndex = DataCenter.shareDataCenter.curShowAllSongId.count-1
        }
        self.start(DataCenter.shareDataCenter.curPlayIndex)
    }
    
    
    @IBAction func nextSong(sender: UIButton) {
        self.next()
    }
    
    func next(){
        DataCenter.shareDataCenter.curPlayIndex++
        if DataCenter.shareDataCenter.curPlayIndex > DataCenter.shareDataCenter.curShowAllSongId.count{
            DataCenter.shareDataCenter.curPlayIndex = 0
        }
        self.start(DataCenter.shareDataCenter.curPlayIndex)
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
        }else{
            DataCenter.shareDataCenter.curPlayStatus = 1
            DataCenter.shareDataCenter.mp.play()
            self.playButton.setImage(UIImage(named: "player_btn_pause_normal"), forState: UIControlState.Normal)
        }
        
    }

}

