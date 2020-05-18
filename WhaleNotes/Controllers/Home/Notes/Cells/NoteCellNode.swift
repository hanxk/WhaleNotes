//
//  NoteCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit

class NoteCellNode: ASCellNode {
    
    enum CardUIConstants {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 8
        static let verticalSpace: CGFloat = 8
    }
    //  let imageNode = ASImageNode()
    let titleNode = ASTextNode()
    let textNode = ASTextNode()
    required init(title : String,text : String) {
        super.init()
        titleNode.attributedText = getTextLabelAttributes(text: title)
        textNode.attributedText = getTextLabelAttributes(text: text)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.textNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stackLayout = ASStackLayoutSpec.vertical()
        stackLayout.justifyContent = .start
        stackLayout.alignItems = .start
        stackLayout.style.flexShrink = 1.0
        stackLayout.spacing = NoteCardCell.CardUIConstants.verticalSpace
        stackLayout.children = [titleNode,textNode]
        
        let insets =  UIEdgeInsets.init(top: CardUIConstants.verticalPadding, left: CardUIConstants.horizontalPadding, bottom: CardUIConstants.verticalPadding, right:  CardUIConstants.horizontalPadding)
        
        return  ASInsetLayoutSpec(insets: insets, child: stackLayout)
    }
    override func didLoad() {
        
        self.view.backgroundColor = .white
        _ = self.view.layer.then {
            $0.cornerRadius = 6
            $0.borderWidth = 1
            $0.borderColor = UIColor(red: 0.875, green: 0.875, blue: 0.875, alpha: 1).cgColor
        }
    }
    
    func getTextLabelAttributes(text: String) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.0
        paragraphStyle.lineHeightMultiple = 0.7
        let attrString = NSMutableAttributedString()
        attrString.append(NSMutableAttributedString(string:text))
        attrString.addAttribute(NSAttributedString.Key.font, value:font, range: NSMakeRange(0, attrString.length))
        return attrString
    }
    
}
