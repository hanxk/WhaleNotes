//
//  FlowCollectionLayoutDelegate.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/20.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit

class FlowCollectionLayoutDelegate: NSObject {
    var layoutInfo:FlowCollectionLayoutInfo!
   
}

extension FlowCollectionLayoutDelegate:ASCollectionLayoutDelegate {
    func scrollableDirections() -> ASScrollDirection {
        return ASScrollDirectionVerticalDirections
    }
    
    func additionalInfoForLayout(withElements elements: ASElementMap) -> Any? {
        return layoutInfo
    }
    
    static func calculateLayout(with context: ASCollectionLayoutContext) -> ASCollectionLayoutState {
        
        let layoutWidth = context.viewportSize.width
        let elements = context.elements!
        
        let layoutInfo = context.additionalInfo as! FlowCollectionLayoutInfo
        
        let insets = layoutInfo.insets
        
        let sectionCount = elements.numberOfSections
        
        var contentHeight:CGFloat = 0
        
        let attrsMap = NSMapTable<ASCollectionElement, UICollectionViewLayoutAttributes>.elementToLayoutAttributes()
        
        for section in 0..<sectionCount {
          
            let numberOfItems = elements.numberOfItems(inSection: section)
            if numberOfItems ==  0 {
                break
            }
            
            // 最终目的：计算高度
            var rowsCount = numberOfItems > 0 ? 1 : 0
            
            var x:CGFloat = insets.left
            var  sectionHeight:CGFloat = 0
            // 计算 item width
            for itemIndex in 0..<numberOfItems {
                let indexPath = IndexPath(row: itemIndex, section: section)
                let element = elements.elementForItem(at: indexPath)!
                
//                x = x == 0 ? insets.left : x + layoutInfo.spacing
//                let x = rowWidth > 0 ? rowWidth + layoutInfo.spacing : 0
                
                
                // 剩余的空间
                
                
                let attrs  = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
                let sizeRange = _sizeRangeForItem(cellNode: element.node, indexPath: indexPath, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
                let itemSize = element.node.layoutThatFits(sizeRange).size
                
                let itemWidth = itemSize.width
                if x != insets.left {
                    x += layoutInfo.spacing
                }
                
                let remainRowWidth = layoutWidth - x - insets.right
                if itemWidth > remainRowWidth {// 换行
                    x = insets.left
                    rowsCount += 1
                }
                
                let y = insets.top + CGFloat(rowsCount-1)*layoutInfo.spacing + CGFloat(rowsCount-1)*layoutInfo.itemHeight
                sectionHeight = y + layoutInfo.itemHeight + insets.bottom
                
                let frame = CGRect(x: x, y: y, width: itemSize.width, height: itemSize.height)
                attrs.frame = frame
                attrsMap.setObject(attrs, forKey: element)
                
                x += itemWidth
                
            }
//            let sectionContentHeight = insets.top + CGFloat(rowsCount-1)*layoutInfo.itemHeight + insets.bottom
            contentHeight += sectionHeight
        }
        let contentSize = CGSize(width: layoutWidth, height: contentHeight)
        return ASCollectionLayoutState(context: context, contentSize: contentSize, elementToLayoutAttributesTable: attrsMap)
    }
    
    static  func _sizeRangeForItem(cellNode:ASCellNode,indexPath:IndexPath,layoutWidth:CGFloat,layoutInfo:FlowCollectionLayoutInfo) -> ASSizeRange {
//        let itemWidth = _columnWidthForSection(section: indexPath.section, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
        let maxColumnWidth = layoutWidth - layoutInfo.insets.left - layoutInfo.insets.right
        return ASSizeRange(min: CGSize(width: 10, height: layoutInfo.itemHeight), max: CGSize(width: maxColumnWidth, height: layoutInfo.itemHeight))
    }
    
    
    static func _widthForSection(section:Int,layoutWidth:CGFloat,layoutInfo:FlowCollectionLayoutInfo) -> CGFloat {
        return layoutWidth - layoutInfo.insets.left - layoutInfo.insets.right
    }
    
}

extension FlowCollectionLayoutDelegate:ASCollectionViewLayoutInspecting {
    func collectionView(_ collectionView: ASCollectionView, constrainedSizeForNodeAt indexPath: IndexPath) -> ASSizeRange {
        return ASSizeRangeZero
    }
    
}
