//
//  MusicListTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/13.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit
import MJRefresh

class MusicListTableViewController: UITableViewController {
    
    var channel:String = "public_tuijian_zhongguohaoshengyin"
    var curChannelList:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.channel = DataCenter.shareDataCenter.currentChannel
        
        HttpRequest.getSongList(self.channel, callback: { (list) -> Void in
            if list == nil {return}
            DataCenter.shareDataCenter.currentAllSongId = list!
            self.loadSongData()
        })
        
        //下拉刷新
        self.tableView.addLegendHeaderWithRefreshingTarget(self, refreshingAction: Selector("refreshList"))
        
        self.tableView.addLegendFooterWithRefreshingTarget(self, refreshingAction: Selector("loadMore"))
    }
    
    func loadSongData(){
        
        self.curChannelList = DataCenter.shareDataCenter.curShowAllSongId
        
        HttpRequest.getSongInfoList(self.curChannelList, callback: { (info) -> Void in
            
            if info == nil {return}
            
            DataCenter.shareDataCenter.curShowAllSongInfo = info!
            self.tableView.reloadData()
            
            self.tableView.header.endRefreshing()
            self.tableView.footer.endRefreshing()
        })
        
        HttpRequest.getSongLinkList(self.curChannelList, callback: { (link) -> Void in
            DataCenter.shareDataCenter.curShowAllSongLink = link!
        })
    }
    
    func refreshList(){
        
        DataCenter.shareDataCenter.curShowStartIndex += 20
        DataCenter.shareDataCenter.curShowEndIndex += 20
        
        if DataCenter.shareDataCenter.curShowEndIndex > DataCenter.shareDataCenter.currentAllSongId.count{
            DataCenter.shareDataCenter.curShowEndIndex = DataCenter.shareDataCenter.currentAllSongId.count
            DataCenter.shareDataCenter.curShowStartIndex = DataCenter.shareDataCenter.curShowEndIndex-20
        }
        
        loadSongData()
    }
    
    func loadMore(){

        DataCenter.shareDataCenter.curShowEndIndex += 20
        
        if DataCenter.shareDataCenter.curShowEndIndex > DataCenter.shareDataCenter.currentAllSongId.count{
            DataCenter.shareDataCenter.curShowEndIndex = DataCenter.shareDataCenter.currentAllSongId.count
            DataCenter.shareDataCenter.curShowStartIndex = DataCenter.shareDataCenter.curShowEndIndex-20
        }
        
        loadSongData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return self.curChannelList.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell
        
        var info =  DataCenter.shareDataCenter.curShowAllSongInfo[indexPath.row]
        
        cell.textLabel?.text = info.name
        //cell.imageView?.kf_setImageWithURL(NSURL(string: info.songPicRadio)!, placeholderImage: nil)
        cell.imageView?.image = UIImage(data: NSData(contentsOfURL: NSURL(string: info.songPicRadio)!)!)
        cell.detailTextLabel?.text = info.artistName
        // Configure the cell...

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        DataCenter.shareDataCenter.curPlayIndex = indexPath.row
        
        NSNotificationCenter.defaultCenter().postNotificationName(CHANNEL_MUSIC_LIST_CLICK_NOTIFICATION, object: nil)
        
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
        })
    }

}
