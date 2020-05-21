//
//  WaterfallCollectionLayoutInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class WaterfallCollectionLayoutInfo:NSObject {
    
    var numberOfColumns:Int
    var columnSpacing:CGFloat
    var interItemSpacing:CGFloat
    var sectionInsets:UIEdgeInsets
    var scrollDirection:ASScrollDirection
    
    init(numberOfColumns:Int,columnSpacing:CGFloat,interItemSpacing:CGFloat,sectionInsets:UIEdgeInsets,scrollDirection:ASScrollDirection) {
        self.numberOfColumns = numberOfColumns
        self.columnSpacing = columnSpacing
        self.interItemSpacing = interItemSpacing
        self.sectionInsets = sectionInsets
        self.scrollDirection = scrollDirection
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return true
    }
    
    override var hash: Int {
        
        var displayOptions = (
            numberOfColumns: self.numberOfColumns,
            columnSpacing: self.columnSpacing,
            interItemSpacing: self.interItemSpacing,
            sectionInsets: self.sectionInsets,
            scrollDirection: self.scrollDirection
        )
        return Int(ASHashBytes(&displayOptions, 5))
    }
    
}
