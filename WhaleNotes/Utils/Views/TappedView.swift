//
//  TappedView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
class TappedView:UIView {
    
    override init(frame: CGRect) {
         super.init(frame: frame)
         backgroundColor = UIColor.clear
     }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
     }

     override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesBegan(touches, with: event)
         backgroundColor = UIColor.tappedColor
     }

     override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
         super.touchesEnded(touches, with: event)
         backgroundColor = UIColor.clear
     }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        backgroundColor = UIColor.clear
    }
}
