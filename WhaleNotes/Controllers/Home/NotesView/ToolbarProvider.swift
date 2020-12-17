//
//  ToolbarProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit


class ToolbarProvider:NoteCardProvider {
    
    var cardActionEmit: ((NoteCardAction) -> Void)?

    private lazy var dateNode :ASTextNode  = ASTextNode().then {
        $0.attributedText = getDateLabelAttributes(text: "今天 10:00")
        $0.maximumNumberOfLines = 1
    }
    
    private var menuButtonNode :ASButtonNode!
    private var editButtonNode :ASButtonNode!
    
    func generateIconButton(imgName:String,cardAction:NoteCardAction) -> ASButtonNode {
       let button = ASButtonNode().then {
            let image = UIImage(systemName: imgName)?.withRenderingMode(.alwaysTemplate)
            $0.setImage(image, for: .normal)
            $0.tintColor = StyleConfig.iconTintColor
            $0.style.minWidth = ASDimensionMakeWithPoints(24)
            $0.style.minHeight = ASDimensionMakeWithPoints(StyleConfig.footerHeight)
            $0.view.tag = cardAction.rawValue
        }
        button.addTarget(self, action: #selector(actionButtonTapped), forControlEvents: .touchUpInside)
        return button
    }
    
    @objc func actionButtonTapped(sender:ASButtonNode) {
        guard  let action = NoteCardAction(rawValue: sender.view.tag) else { return }
        self.cardActionEmit?(action)
    }
}

extension  ToolbarProvider {
    
    func attach(cell: ASCellNode) {
        
        menuButtonNode = generateIconButton(imgName: "ellipsis", cardAction: .menu)
        editButtonNode = generateIconButton(imgName: "pencil", cardAction: .edit)
        
        cell.addSubnode(dateNode)
        cell.addSubnode(menuButtonNode)
        cell.addSubnode(editButtonNode)
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let footerLayout = ASStackLayoutSpec.horizontal().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.justifyContent = .spaceBetween
            $0.alignItems = .center
            $0.style.minHeight = ASDimensionMakeWithPoints(StyleConfig.footerHeight)
        }
        
        let rightLayoutSpec = ASStackLayoutSpec.horizontal().then {
            $0.spacing = 10
        }
        rightLayoutSpec.children = [menuButtonNode,editButtonNode]
        
        footerLayout.children = [dateNode,rightLayoutSpec]
        return footerLayout
    }

    
    func getDateLabelAttributes(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.cardTextSecondary,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    
}
