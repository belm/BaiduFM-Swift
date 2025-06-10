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
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // 异步加载数据并更新UI
        Task {
            if DataManager.shared.songInfoList.isEmpty {
                await DataManager.shared.getTop20SongInfoList()
            }
            await MainActor.run {
                self.loadTable()
            }
        }
    }
    
    func loadTable(){
        
        self.table.setNumberOfRows(DataManager.shared.songInfoList.count, withRowType: "tableRow")
        
        for i:Int in 0..<self.table.numberOfRows {
            
            let song:SongInfo = DataManager.shared.songInfoList[i]
            let row = self.table.rowController(at: i) as! MusicTableRow
            row.nameLabel.setText(song.name)
            row.artistLabel.setText(song.artistName)

            if let url = URL(string: song.songPicRadio) {
                DispatchQueue.global(qos: .userInitiated).async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            row.image.setImageData(data)
                        }
                    }
                }
            }
        }
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        
        DataManager.shared.curIndex = rowIndex
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
