//
//  SongListInterfaceController.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/26.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import WatchKit
import Foundation


class SongListInterfaceController: WKInterfaceController {
    
    @IBOutlet weak var table: WKInterfaceTable!
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if context != nil {
            //分类列表点击过来
            DataManager.getTop20SongInfoList { () -> Void in
                self.loadTable()
            }
        }else{
            //首页菜单点击过来
            self.loadTable()
        }
    }
    
    func loadTable(){
        
        self.table.setNumberOfRows(DataManager.shareDataManager.songInfoList.count, withRowType: "tableRow")
        
        for i:Int in 0..<self.table.numberOfRows {
            
            let song:SongInfo = DataManager.shareDataManager.songInfoList[i]
            let row:MusicTableRow = self.table.rowControllerAtIndex(i) as! MusicTableRow
            row.image.setImageData(NSData(contentsOfURL: NSURL(string: song.songPicRadio)!)!)
            row.nameLabel.setText(song.name)
            row.artistLabel.setText(song.artistName)
        }
    }
    
    override func table(table: WKInterfaceTable, didSelectRowAtIndex rowIndex: Int) {
        
        DataManager.shareDataManager.curIndex = rowIndex
        self.popToRootController()
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
