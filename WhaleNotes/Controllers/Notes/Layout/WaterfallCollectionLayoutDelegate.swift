//
//  WaterfallCollectionLayoutDelegate.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class WaterfallCollectionLayoutDelegate: NSObject {
    var layoutInfo:WaterfallCollectionLayoutInfo!
   
}

extension WaterfallCollectionLayoutDelegate:ASCollectionLayoutDelegate {
    func scrollableDirections() -> ASScrollDirection {
        return layoutInfo.scrollDirection
    }
    
    func additionalInfoForLayout(withElements elements: ASElementMap) -> Any? {
        return layoutInfo
    }
    
    static func calculateLayout(with context: ASCollectionLayoutContext) -> ASCollectionLayoutState {
        
        let layoutWidth = context.viewportSize.width
        let elements = context.elements!
        
        let layoutInfo = context.additionalInfo as! WaterfallCollectionLayoutInfo
        
        
        let sectionCount = elements.numberOfSections
        
        var contentHeight:CGFloat = 0
        
        let attrsMap = NSMapTable<ASCollectionElement, UICollectionViewLayoutAttributes>.elementToLayoutAttributes()
        
        for section in 0..<sectionCount {
          
            let numberOfItems = elements.numberOfItems(inSection: section)
            if numberOfItems ==  0 {
                break
            }
            let itemWidth = _columnWidthForSection(section: section, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
            
            // 存储列高
            var columnHeights:[CGFloat] = []
            for _ in 0..<layoutInfo.numberOfColumns {
                columnHeights.append(layoutInfo.sectionInsets.top)
            }
            
            for itemIndex in 0..<numberOfItems {
                let indexPath = IndexPath(row: itemIndex, section: section)
                let element = elements.elementForItem(at: indexPath)!
                
                let attrs  = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
                let sizeRange = _sizeRangeForItem(cellNode: element.node, indexPath: indexPath, columnWidth: itemWidth, layoutInfo: layoutInfo)
                
                let size = element.node.layoutThatFits(sizeRange).size
                
                let columnIndex = getLowestColumnIndex(columnHeights: columnHeights)
                let aa = CGFloat(columnIndex) * itemWidth + CGFloat(columnIndex) * layoutInfo.columnSpacing
                let x = layoutInfo.sectionInsets.left + aa
                
                var y = columnHeights[columnIndex]
                if y != layoutInfo.sectionInsets.top {
                    y += layoutInfo.interItemSpacing
                }
                
                let frame = CGRect(x: x, y: y, width: size.width, height: size.height)
                attrs.frame = frame
                attrsMap.setObject(attrs, forKey: element)
                
                // 更新列高
                columnHeights[columnIndex] = frame.maxY
            }
            
            contentHeight  += columnHeights.max() ?? 0
        }
        contentHeight += layoutInfo.sectionInsets.bottom
        let contentSize = CGSize(width: layoutWidth, height: contentHeight)
        return ASCollectionLayoutState(context: context, contentSize: contentSize, elementToLayoutAttributesTable: attrsMap)
    }
    
    static func getLowestColumnIndex(columnHeights: [CGFloat]) -> Int {
        var lowestHeight = CGFloat.greatestFiniteMagnitude
        var lowestIndex = 0
        for (index,height) in columnHeights.enumerated() {
            if height < lowestHeight {
                lowestHeight = height
                lowestIndex = index
            }
        }
        return lowestIndex
    }
    
    
    static func getTallestColumnIndex(columnHeights: [CGFloat]) -> Int {
        var lowestHeight = CGFloat.greatestFiniteMagnitude
        var lowestIndex = 0
        for (index,height) in columnHeights.enumerated() {
            if height < lowestHeight {
                lowestHeight = height
                lowestIndex = index
            }
        }
        return lowestIndex
    }
    
//    static func calculateLayout(with context: ASCollectionLayoutContext) -> ASCollectionLayoutState {
//
//        let layoutWidth = context.viewportSize.width
//        let elements = context.elements!
//
//        var top:CGFloat = 0
//        let layoutInfo = context.additionalInfo as! WaterfallCollectionLayoutInfo
//
//        let sectionCount = elements.numberOfSections
//
//        // 多个 section
//        var columnHeights:[[CGFloat]] = [[]]
//
//        let attrsMap = NSMapTable<ASCollectionElement, UICollectionViewLayoutAttributes>.elementToLayoutAttributes()
//
//        for section in 0..<sectionCount {
//
//            let numberOfItems = elements.numberOfItems(inSection: section)
//            if numberOfItems == 0 {
//                break
//            }
//
//            top += layoutInfo.sectionInsets.top;
//
//            // 初始化 column heights 容器
//            columnHeights.append([])
//            for _ in 0..<numberOfItems {
//                columnHeights[section].append(top)
//            }
//
//            let columnWidth = _columnWidthForSection(section: section, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
//
//            for idx in 0..<numberOfItems {
//                let columnIndex = _shortestColumnIndexInSection(section: section, columnHeights: columnHeights)
//                let indexPath = IndexPath(row: idx, section: section)
//                let element = elements.elementForItem(at: indexPath)!
//
//                let attrs  = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
//                let sizeRange = _sizeRangeForItem(cellNode: element.node, indexPath: indexPath, columnWidth: columnWidth, layoutInfo: layoutInfo)
//
//                let size = element.node.layoutThatFits(sizeRange).size
//
//                var x = layoutInfo.sectionInsets.left + (columnWidth + layoutInfo.columnSpacing) * CGFloat(columnIndex)
//                if x  == 0 {
//                    x = layoutInfo.sectionInsets.left
//                }
//
//                let y = columnHeights[section][columnIndex]
//                let position = CGPoint(x: x, y: y)
//
//                let frame = CGRect(x: position.x, y: position.y, width: size.width, height: size.height)
//                attrs.frame = frame
//
//                attrsMap.setObject(attrs, forKey: element)
//
//                columnHeights[section][columnIndex] = frame.maxY + layoutInfo.interItemSpacing
//
//            }
//
//            let columnIndex = _tallestColumnIndexInSection(section: section, columnHeights: columnHeights)
//            top = columnHeights[section][columnIndex] - layoutInfo.interItemSpacing + layoutInfo.sectionInsets.bottom
//
//            let columnCount = columnHeights[section].count
//            for i in 0..<columnCount {
//                columnHeights[section][i] = top
//            }
//
//        }
//        let contentHeight = columnHeights.last?.first ?? 0
//        let contentSize = CGSize(width: layoutWidth, height: contentHeight)
//        return ASCollectionLayoutState(context: context, contentSize: contentSize, elementToLayoutAttributesTable: attrsMap)
//    }
    
    static func _tallestColumnIndexInSection(section:Int,columnHeights:[[CGFloat]]) -> Int {
        var columnIndex = 0
        var shortestHeight = CGFloat.greatestFiniteMagnitude
        for (index,height) in columnHeights[section].enumerated() {
            if (height > shortestHeight) {
                columnIndex = index
                shortestHeight = height
            }
        }
        return columnIndex
    }
    
    
    static func _shortestColumnIndexInSection(section:Int,columnHeights:[[CGFloat]]) -> Int {
        var columnIndex = 0
        var shortestHeight = CGFloat.greatestFiniteMagnitude
        for (index,height) in columnHeights[section].enumerated() {
            if (height < shortestHeight) {
                columnIndex = index
                shortestHeight = height
            }
        }
        return columnIndex
    }
    static  func _sizeRangeForItem(cellNode:ASCellNode,indexPath:IndexPath,columnWidth:CGFloat,layoutInfo:WaterfallCollectionLayoutInfo) -> ASSizeRange {
//        let itemWidth = _columnWidthForSection(section: indexPath.section, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
        return ASSizeRange(min: CGSize(width: columnWidth, height: 0), max: CGSize(width: columnWidth, height: CGFloat.greatestFiniteMagnitude))
    }
    
    
    static func _columnWidthForSection(section:Int,layoutWidth:CGFloat,layoutInfo:WaterfallCollectionLayoutInfo) -> CGFloat{
        
        let columnCount = CGFloat(layoutInfo.numberOfColumns)
        
        let sectionWith = _widthForSection(section: section, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
        let space = (columnCount-1) * layoutInfo.columnSpacing
        return (sectionWith - space)/columnCount
    }
    
    static func _widthForSection(section:Int,layoutWidth:CGFloat,layoutInfo:WaterfallCollectionLayoutInfo) -> CGFloat {
        return layoutWidth - layoutInfo.sectionInsets.left - layoutInfo.sectionInsets.right
    }
    
    
    
}

extension WaterfallCollectionLayoutDelegate:ASCollectionViewLayoutInspecting {
    func collectionView(_ collectionView: ASCollectionView, constrainedSizeForNodeAt indexPath: IndexPath) -> ASSizeRange {
        return ASSizeRangeZero
    }
    
}
