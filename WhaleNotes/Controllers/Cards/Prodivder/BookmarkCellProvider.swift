//
//  BookmarkCellProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/28.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class BookmarkCellProvider:CellProvider {
    private let bookmarkBlock:BlockInfo!
    private var properties:BlockBookmarkProperty {
        return bookmarkBlock.blockBookmarkProperties!
    }
    
    private lazy var coverNode:ASImageNode  = ASImageNode().then {
        $0.contentMode = .scaleAspectFill
        if let imgUrl = bookmarkBlock.blockBookmarkProperties?.coverProperty?.url {
            let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imgUrl).absoluteString
            let image  = UIImage(contentsOfFile: imageUrlPath)
            $0.image = image
        }
        $0.clipsToBounds = true
        $0.backgroundColor = UIColor(hexString: "#DDDDDD")
//        $0.cornerRoundingType = .precomposited
        $0.cornerRadius = NoteCellConstants.cornerRadius
//        $0.cornerRoundingType = .precomposited
//        $0.cornerRadius = NoteCellConstants.cornerRadius
    }
    
    
    private lazy var iconNode:ASImageNode  = ASImageNode().then {
//        $0.contentMode = .scaleAspectFill
        let image  = UIImage(systemName: "link", pointSize: 10)?.withTintColor(UIColor(hexString: "#666666"))
        $0.image = image
//        $0.forcedSize = CGSize(width: 10, height: 10)
//        if let imgUrl = bookmarkBlock.blockBookmarkProperties?.coverProperty?.url {
//            let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imgUrl).absoluteString
//        }
    }
    
    
    private lazy var titleNode:ASTextNode  = ASTextNode().then {
        $0.attributedText = getTitleLabelAttributes(text: properties.title)
        $0.maximumNumberOfLines = 3
    }
    
    private lazy var urlNode:ASTextNode  = ASTextNode().then {
        $0.attributedText = getUrlLabelAttributes(text: properties.canonicalUrl)
        $0.maximumNumberOfLines = 2
    }
    
    init(bookmarkBlock:BlockInfo) {
        self.bookmarkBlock = bookmarkBlock
    }
    
    func attach(cell: ASCellNode) {
        cell.addSubnode(coverNode)
        cell.addSubnode(titleNode)
        cell.addSubnode(iconNode)
        cell.addSubnode(urlNode)
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let imageWidth = constrainedSize.max.width - BoardViewConstants.cellShadowSize * 2
        let ratioHeight = imageWidth * 100 / 170
//        let ratioHeight:CGFloat = 120
        coverNode.style.width = ASDimensionMake(imageWidth)
        coverNode.style.height = ASDimensionMake(ratioHeight)
        
        iconNode.style.width  = ASDimensionMake(13)
        iconNode.style.height  = ASDimensionMake(13)
        
        let linkLayout = ASStackLayoutSpec.horizontal()
        linkLayout.children = [iconNode,urlNode]
        linkLayout.spacing = 2
        linkLayout.alignItems =  .center
        
        let vLayout = ASStackLayoutSpec.vertical()
        vLayout.children = [titleNode,linkLayout]
        vLayout.spacing = 4
        
        let insets =  UIEdgeInsets.init(top: 8, left: NoteCellConstants.horizontalPadding, bottom: NoteCellConstants.verticalPadding, right:  NoteCellConstants.horizontalPadding)
        let insetLayout = ASInsetLayoutSpec(insets: insets, child: vLayout)
        
        let rootLayout = ASStackLayoutSpec.vertical()
        rootLayout.children = [coverNode,insetLayout]
        return rootLayout
        
        
    }
    
    
}

extension BookmarkCellProvider {
    
    func getTitleLabelAttributes(text: String) -> NSAttributedString {
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineSpacing = 1.8
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            .foregroundColor: UIColor.cardText,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    func getUrlLabelAttributes(text: String) -> NSAttributedString {
//        let paragraphStyle = NSMutableParagraphStyle()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: UIColor.cardTextSecondary,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
}
