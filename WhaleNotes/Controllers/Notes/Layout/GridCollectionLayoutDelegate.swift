//
//  GridCollectionLayoutDelegate.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class GridCollectionLayoutDelegate: NSObject {
}


extension GridCollectionLayoutDelegate:ASCollectionLayoutDelegate {
    func scrollableDirections() -> ASScrollDirection {
        return ASScrollDirectionVerticalDirections
    }
    
    func additionalInfoForLayout(withElements elements: ASElementMap) -> Any? {
        return nil
    }
    
    static func calculateLayout(with context: ASCollectionLayoutContext) -> ASCollectionLayoutState {
        
//        let layoutWidth = context.viewportSize.width
//        let elements = context.elements!
//
//        let layoutInfo = context.additionalInfo as! WaterfallCollectionLayoutInfo
//
//
//        let sectionCount = elements.numberOfSections
//
//        var contentHeight:CGFloat = 0
//
        let attrsMap = NSMapTable<ASCollectionElement, UICollectionViewLayoutAttributes>.elementToLayoutAttributes()
//
//        for section in 0..<sectionCount {
//
//            let numberOfItems = elements.numberOfItems(inSection: section)
//            if numberOfItems ==  0 {
//                break
//            }
//            let itemWidth = _columnWidthForSection(section: section, layoutWidth: layoutWidth, layoutInfo: layoutInfo)
//
//            // 存储列高
//            var columnHeights:[CGFloat] = []
//            for _ in 0..<layoutInfo.numberOfColumns {
//                columnHeights.append(layoutInfo.sectionInsets.top)
//            }
//
//            for itemIndex in 0..<numberOfItems {
//                let indexPath = IndexPath(row: itemIndex, section: section)
//                let element = elements.elementForItem(at: indexPath)!
//
//                let attrs  = UICollectionViewLayoutAttributes.init(forCellWith: indexPath)
//                let sizeRange = _sizeRangeForItem(cellNode: element.node, indexPath: indexPath, columnWidth: itemWidth, layoutInfo: layoutInfo)
//
//                let size = element.node.layoutThatFits(sizeRange).size
//
//                let columnIndex = getLowestColumnIndex(columnHeights: columnHeights)
//                let aa = CGFloat(columnIndex) * itemWidth + CGFloat(columnIndex) * layoutInfo.columnSpacing
//                let x = layoutInfo.sectionInsets.left + aa
//
//                var y = columnHeights[columnIndex]
//                if y != layoutInfo.sectionInsets.top {
//                    y += layoutInfo.interItemSpacing
//                }
//
//                let frame = CGRect(x: x, y: y, width: size.width, height: size.height)
//                attrs.frame = frame
//                attrsMap.setObject(attrs, forKey: element)
//
//                // 更新列高
//                columnHeights[columnIndex] = frame.maxY
//            }
//
//            contentHeight  += columnHeights.max() ?? 0
//        }
//        contentHeight += layoutInfo.sectionInsets.bottom
//        let contentSize = CGSize(width: layoutWidth, height: contentHeight)
        return ASCollectionLayoutState(context: context, contentSize: CGSize.zero, elementToLayoutAttributesTable: attrsMap)
    }
    
}

extension GridCollectionLayoutDelegate:ASCollectionViewLayoutInspecting {
    func collectionView(_ collectionView: ASCollectionView, constrainedSizeForNodeAt indexPath: IndexPath) -> ASSizeRange {
        return ASSizeRangeZero
    }
    
}
