//
//  RoundImageView.swift
//  BaiduFM
//
//  Created by lumeng on 15/4/21.
//  Copyright (c) 2015年 lumeng. All rights reserved.
//

import UIKit

class RoundImageView: UIImageView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //设置圆角
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.size.width/2
        
        //边框
        self.layer.borderWidth = 4
        self.layer.borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7).CGColor
    }
    
    func rotation(){
        
        var animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = M_PI*2.0
        animation.duration = 20
        animation.repeatCount = 1000
        self.layer.addAnimation(animation, forKey: nil)
    }

}
