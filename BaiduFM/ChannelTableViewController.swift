//
//  ChannelTableViewController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/13.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit

class ChannelTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if DataCenter.shareDataCenter.channelListInfo.count == 0 {
            HttpRequest.getChannelList { (list) -> Void in
                if list == nil {
                    return
                }
                DataCenter.shareDataCenter.channelListInfo = list!
                self.tableView.reloadData()
            }
        }
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
        return DataCenter.shareDataCenter.channelListInfo.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        cell.textLabel?.text = DataCenter.shareDataCenter.channelListInfo[indexPath.row].name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath){
        
        var channel = DataCenter.shareDataCenter.channelListInfo[indexPath.row]
        DataCenter.shareDataCenter.currentChannel = channel.id
        
        NSUserDefaults.standardUserDefaults().setValue(channel.id, forKey: "LAST_PLAY_CHANNEL_ID")
        NSUserDefaults.standardUserDefaults().setValue(channel.name, forKey: "LAST_PLAY_CHANNEL_NAME")
        
    }

}
