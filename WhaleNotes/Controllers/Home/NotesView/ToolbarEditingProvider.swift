//
//  NoteCardProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit

class ToolbarEditingProvider:NoteCardProvider {
    
    private var tagButtonNode :ASButtonNode!
    private var photoButtonNode :ASButtonNode!
    var cardActionEmit: ((NoteCardAction) -> Void)?
    
    private lazy var saveButtonNode :ASButtonNode  = ASButtonNode().then {
        $0.backgroundColor = .brand
        $0.setTitle("完成", with: UIFont.systemFont(ofSize: 14,weight: .medium), with: .white, for: .normal)
        $0.cornerRadius = 6
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        $0.style.height = ASDimensionMakeWithPoints(30)
        $0.view.tag = NoteCardAction.save.rawValue
        $0.addTarget(self, action: #selector(actionButtonTapped), forControlEvents: .touchUpInside)
    }
    
//    private lazy var saveButtonNode = ASDisplayNode { () -> UIButton in
//          let button = ActionButton()
//        button.setTitle("完成", for: .normal)
//          button.backgroundColor = UIColor.brand
//        button.frame = CGRect(x: 0, y: 0, width: 54, height: 30)
//        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
//          button.cornerRadius = 4
//          button.setTitleColor(UIColor.red, for: .normal)
//          button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
//        button.tag = NoteCardAction.save.rawValue
//        button.addTarget(self, action: #selector(self.actionButtonTapped), for: .touchUpInside)
//          return button
//      }
}

extension ToolbarEditingProvider {
    
    func attach(cell: ASCellNode) {
        
        tagButtonNode = generateIconButton(imgName: "tag", cardAction: .tag)
        
        photoButtonNode = generateIconButton(imgName: "photo", cardAction: .save)
        
        saveButtonNode.style.height = ASDimensionMakeWithPoints(30)
        cell.addSubnode(tagButtonNode)
        cell.addSubnode(photoButtonNode)
        cell.addSubnode(saveButtonNode)
    }
    
    func generateIconButton(imgName:String,cardAction:NoteCardAction) -> ASButtonNode {
       let button = ASButtonNode().then {
        let image = UIImage(systemName: imgName,pointSize: 16)?.withRenderingMode(.alwaysTemplate)
            $0.setImage(image, for: .normal)
            $0.tintColor = UIColor(hexString: "#6F6F6F")
            $0.style.minWidth = ASDimensionMakeWithPoints(28)
            $0.style.minHeight = ASDimensionMakeWithPoints(StyleConfig.footerHeight)
            $0.view.tag = cardAction.rawValue
        }
        button.addTarget(self, action: #selector(actionButtonTapped), forControlEvents: .touchUpInside)
        return button
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let leftLayoutSpec = ASStackLayoutSpec.horizontal().then {
            $0.spacing = 10
        }
        leftLayoutSpec.children = [tagButtonNode,photoButtonNode]
        
        let rightLayoutSpec = ASStackLayoutSpec.horizontal().then {
            $0.spacing = 10
        }
        rightLayoutSpec.children = [saveButtonNode]
        
        
        let footerLayout = ASStackLayoutSpec.horizontal().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.justifyContent = .spaceBetween
            $0.alignItems = .center
            $0.style.minHeight = ASDimensionMakeWithPoints(StyleConfig.footerHeight)
        }
        footerLayout.children = [leftLayoutSpec,rightLayoutSpec]
        return footerLayout
    }

    
    @objc func actionButtonTapped(sender:ASButtonNode) {
        guard  let action = NoteCardAction(rawValue: sender.view.tag) else { return }
        self.cardActionEmit?(action)
    }
}
