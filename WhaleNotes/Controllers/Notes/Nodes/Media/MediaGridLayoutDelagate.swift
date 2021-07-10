//
//  MediaGridLayout.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class MediaGridLayoutDelagate: NSObject {
    var layoutInfo:MediaGridCollectionLayoutInfo!
    init(layoutInfo:MediaGridCollectionLayoutInfo) {
        self.layoutInfo = layoutInfo
    }
   
}

//enum MediaGridLayoutConstants {
//    static let columnCount = 3
//    static let spacing:CGFloat = 4
//}

extension MediaGridLayoutDelagate:ASCollectionLayoutDelegate {
    func scrollableDirections() -> ASScrollDirection {
        return ASScrollDirectionVerticalDirections
    }
    
    func additionalInfoForLayout(withElements elements: ASElementMap) -> Any? {
        return layoutInfo
    }
    
    static func calculateLayout(with context: ASCollectionLayoutContext) -> ASCollectionLayoutState {
        
//        let layoutWidth = context.viewportSize.width
//        let elements = context.elements!
//
        let layoutInfo = context.additionalInfo as! MediaGridCollectionLayoutInfo
//
//        let insets = layoutInfo.insets
//
//        let sectionCount = elements.numberOfSections
//
//        var contentHeight:CGFloat = 0
//
//        let attrsMap = NSMapTable<ASCollectionElement, UICollectionViewLayoutAttributes>.elementToLayoutAttributes()
//
//        for section in 0..<sectionCount {
//
//            let numberOfItems = elements.numberOfItems(inSection: section)
//            if numberOfItems ==  0 {
//                break
//            }
//
//            // 最终目的：计算高度
//            var rowsCount = numberOfItems > 0 ? 1 : 0
//
//            var x:CGFloat = insets.left
//            var  sectionHeight:CGFloat = 0
//            // 计算 item width
//            for itemIndex in 0..<numberOfItems {
//                let indexPath = IndexPath(row: itemIndex, section: section)
//                let element = elements.elementForItem(at: indexPath)!
//
//                let attrs  = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
//                let sizeRange = _sizeRangeForItem(cellNode: element.node, indexPath: indexPath, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
//                let itemSize = element.node.layoutThatFits(sizeRange).size
//
//                let itemWidth =  itemSize.width
//                if x != insets.left {
//                    x += layoutInfo.spacing
//                }
//
//                let remainRowWidth = layoutWidth - x - insets.right
//                if itemWidth > remainRowWidth {// 换行
//                    x = insets.left
//                    rowsCount += 1
//                }
//
//                let y = insets.top + CGFloat(rowsCount-1)*layoutInfo.spacing + CGFloat(rowsCount-1)*layoutInfo.itemHeight
//                sectionHeight = y + layoutInfo.itemHeight + insets.bottom
//
//                let frame = CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
//                attrs.frame = frame
//                attrsMap.setObject(attrs, forKey: element)
//
//                x += itemWidth
//
//            }
//            contentHeight += sectionHeight
//        }
        
        var layoutWidth = context.viewportSize.width
        let elements = context.elements!
        
//        elements.count / 3 + 1
        //计算行数，得出高度
        let rowsCount = MediaGridLayoutDelagate.calcRowsCount(count: Int(elements.count), columnCount: layoutInfo.columnCount)
        
        let itemWidth = layoutWidth - CGFloat(layoutInfo.columnCount - 1) * layoutInfo.spacing
        
        let contentHeight:CGFloat = itemWidth*CGFloat(rowsCount)
        let attrsMap = NSMapTable<ASCollectionElement, UICollectionViewLayoutAttributes>.elementToLayoutAttributes()
        
//        let sizeRange = _sizeRangeForItem(cellNode: element.node, indexPath: indexPath, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
//        let itemSize = element.node.layoutThatFits(sizeRange).size
        
        let contentSize = CGSize(width: layoutWidth, height: contentHeight)
        return ASCollectionLayoutState(context: context, contentSize: contentSize, elementToLayoutAttributesTable: attrsMap)
    }
    
    static func calcRowsCount(count:Int,columnCount:Int) -> Int {
        if count <= columnCount {
            return 1
        }
        if count % columnCount == 0 {
            return count /  columnCount
        }
        return count / columnCount  + 1
    }
    
//    static  func _sizeRangeForItem(cellNode:ASCellNode,indexPath:IndexPath,layoutWidth:CGFloat,layoutInfo:MediaGridCollectionLayoutInfo) -> ASSizeRange {
//        let maxColumnWidth = layoutWidth - layoutInfo.insets.left - layoutInfo.insets.right
//        return ASSizeRange(min: CGSize(width: 10, height: layoutInfo.itemHeight), max: CGSize(width: maxColumnWidth, height: layoutInfo.itemHeight))
//    }
    
    
    static func _widthForSection(section:Int,layoutWidth:CGFloat,layoutInfo:MediaGridCollectionLayoutInfo) -> CGFloat {
        return layoutWidth - layoutInfo.insets.left - layoutInfo.insets.right
    }
    
}

extension MediaGridLayoutDelagate:ASCollectionViewLayoutInspecting {
    func collectionView(_ collectionView: ASCollectionView, constrainedSizeForNodeAt indexPath: IndexPath) -> ASSizeRange {
        return ASSizeRangeZero
    }
    
}

class MediaGridCollectionLayoutInfo:NSObject {
    
    var insets:UIEdgeInsets
    var spacing:CGFloat
    var columnCount:Int
    
    init(insets:UIEdgeInsets,spacing:CGFloat,columnCount:Int) {
        self.insets = insets
        self.spacing = spacing
        self.columnCount = columnCount
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        return true
    }
    
    override var hash: Int {
        
        var displayOptions = (
            inset: self.insets,
            spacing: self.spacing,
            itemHeight: self.columnCount
        )
        return Int(ASHashBytes(&displayOptions, 5))
    }
    
}
