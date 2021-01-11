//
//  ImageCellProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/29.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ImageCellProvider:CellProvider {
    private let imageBlock:BlockInfo!
    private var properties:BlockImageProperty {
        return imageBlock.blockImageProperties!
    }
    
    private lazy var imageNode:ASImageNode  = ASImageNode().then {
        $0.contentMode = .scaleAspectFill
        let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.blockImageProperties!.url).absoluteString
        let image  = UIImage(contentsOfFile: imageUrlPath)
        $0.image = image
        $0.cornerRoundingType = .precomposited
        $0.cornerRadius = NoteCellConstants.cornerRadius
    }
    
    init(imageBlock:BlockInfo) {
        self.imageBlock = imageBlock
    }
    
    func attach(cell: ASCellNode) {
        
        cell.addSubnode(imageNode)
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let contentLayout = ASStackLayoutSpec.vertical()
        contentLayout.children = [imageNode]
        
        let imageWidth = constrainedSize.max.width - BoardViewConstants.cellShadowSize * 2
        let ratioHeight = imageWidth * CGFloat(properties.height) / CGFloat(properties.width)
        imageNode.style.height = ASDimensionMake(ratioHeight)
        return contentLayout
    }
    
    
}
