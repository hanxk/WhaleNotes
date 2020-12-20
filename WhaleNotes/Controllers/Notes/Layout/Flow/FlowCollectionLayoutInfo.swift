//
//  FlowCollectionLayoutInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class FlowCollectionLayoutInfo:NSObject {
    
    var insets:UIEdgeInsets
    var spacing:CGFloat
    var itemHeight:CGFloat
    
    init(insets:UIEdgeInsets,spacing:CGFloat,itemHeight:CGFloat) {
        self.insets = insets
        self.spacing = spacing
        self.itemHeight = itemHeight
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return true
    }
    
    override var hash: Int {
        
        var displayOptions = (
            inset: self.insets,
            spacing: self.spacing,
            itemHeight: self.itemHeight
        )
        return Int(ASHashBytes(&displayOptions, 5))
    }
    
}
