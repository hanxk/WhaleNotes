//
//  NoteProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/29.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

protocol CellProvider {
    func attach(cell:ASCellNode)
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec
}


enum NoteCellConstants {
    
    static  let cornerRadius:CGFloat = 8
    
    static let horizontalPadding: CGFloat = 12
    static let verticalPadding: CGFloat = 12
    static let verticalPaddingBottom: CGFloat = 4
    static let attachHeigh: CGFloat = 74
    
    static let contentVerticalSpacing: CGFloat = 2
    
    
    static let titleSpace: CGFloat = 4
    
    static let todoHeight:CGFloat = 22
    static let todoVSpace:CGFloat = 0
    static let todoTextSpace:CGFloat = 2
    static let todoImageSize: CGFloat = 15
    static let todoTextSize: CGFloat = 14
    
    static let bottomHeight: CGFloat = 24
    
    static let boardHeight: CGFloat = 32
    
    static let imageHeight: CGFloat = 74
}

class NoteCellProvider:CellProvider {
    private var titleNode:ASTextNode?
    private var textNode:ASTextNode?
    
    private var cell:ASCellNode!
    private var noteBlock:BlockInfo!
    
    init(noteBlock: BlockInfo) {
        self.noteBlock = noteBlock
    }
    
    func attach(cell:ASCellNode) {
        if noteBlock.title.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTitleLabelAttributes(text: noteBlock.title)
            cell.addSubnode(titleNode)
                      self.titleNode = titleNode
        }
        
        if let textProperties = noteBlock.noteProperties {
            let textNode = ASTextNode()
            print(textProperties.text)
            textNode.attributedText = getTextLabelAttributes(text: textProperties.text)
            textNode.truncationMode = .byTruncatingTail
            textNode.maximumNumberOfLines = 12
            
            self.textNode = textNode
            cell.addSubnode(textNode)
        }
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets =  UIEdgeInsets.init(top: NoteCellConstants.verticalPadding, left: NoteCellConstants.horizontalPadding, bottom: NoteCellConstants.verticalPadding, right:  NoteCellConstants.horizontalPadding)
        
        let contentLayout = ASStackLayoutSpec.vertical().then {
            $0.spacing =  NoteCellConstants.titleSpace
            $0.style.flexShrink = 1.0
            $0.style.flexGrow = 1.0
        }
        
        if let titleNode = titleNode {
            contentLayout.children?.append(titleNode)
        }
        
        if let textNode = textNode {
            contentLayout.children?.append(textNode)
        }
        
        return ASInsetLayoutSpec(insets: insets, child: contentLayout)
    }
    
}


extension NoteCellProvider {
    
    func getTitleLabelAttributes(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.cardText,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    func getTextLabelAttributes(text: String) -> NSAttributedString {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.cardText,
            .paragraphStyle:paragraphStyle
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString
    }
    
    func getMenuLabelAttributes(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor:  UIColor.init(hexString: "#999999"),
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
}
