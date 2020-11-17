//
//  TodoCellProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/20.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit

class TodoCellProvider:CellProvider {
    private var titleNode:ASTextNode?
    private var chkElements:[ASLayoutElement] = []
    private let todoListBlock:BlockInfo!
    private var properties:BlockTodoListProperty {
        return todoListBlock.blockTodoListProperties!
    }
    
    private var todosElements:[ASLayoutElement] = []
    private let maxCount = 8
    
    init(todoBlock:BlockInfo) {
        self.todoListBlock = todoBlock
    }
    
    func attach(cell: ASCellNode) {
        
        if todoListBlock.title.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTitleLabelAttributes(text: todoListBlock.title)
            cell.addSubnode(titleNode)
            self.titleNode = titleNode
        }
        
        let todoBlocks = todoListBlock.contents
        for (index,block) in todoBlocks.enumerated() {
            let imageNode = ASImageNode().then {
                let systemName =  block.blockTodoProperties!.isChecked ? "checkmark.square" :  "square"
                let chkColor = UIColor.primaryText
                $0.image = UIImage(systemName: systemName, pointSize: NoteCellConstants.todoImageSize, weight: .ultraLight)?.withTintColor(chkColor)
                $0.style.height = ASDimensionMake(NoteCellConstants.todoHeight)
                //                $0.style.width = 14
                $0.contentMode = .left
                //                $0.backgroundColor = .red
            }
            cell.addSubnode(imageNode)
            self.chkElements.append(imageNode)
            
            let todoNode = ASTextNode().then {
                $0.attributedText = getTodoTextAttributes(text: block.title,isChecked: block.blockTodoProperties!.isChecked)
                $0.style.flexShrink = 1.0
                $0.maximumNumberOfLines = 2
                $0.truncationMode = .byTruncatingTail
                $0.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
            }
            cell.addSubnode(todoNode)
            self.todosElements.append(todoNode)
            
            if index == maxCount - 1 {
                break
            }
        }
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let todosVLayout = ASStackLayoutSpec.vertical()
        todosVLayout.justifyContent = .start
        todosVLayout.alignItems = .start
        todosVLayout.style.flexShrink = 1.0
        todosVLayout.spacing = NoteCellConstants.todoVSpace
        for i in 0..<todosElements.count {
            let todoStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                  spacing: NoteCellConstants.todoTextSpace,
                                                  justifyContent: .start,
                                                  alignItems: .start,
                                                  children: [chkElements[i],todosElements[i]])
            todoStackSpec.style.flexShrink = 1.0
            todosVLayout.children?.append(todoStackSpec)
        }
        
        let insets =  UIEdgeInsets.init(top: NoteCellConstants.verticalPadding, left: NoteCellConstants.horizontalPadding, bottom: NoteCellConstants.verticalPadding, right:  NoteCellConstants.horizontalPadding)
        
        if let titleNote = self.titleNode {
            let contentLayout = ASStackLayoutSpec.vertical().then {
                $0.spacing = NoteCellConstants.titleSpace
                $0.style.flexShrink = 1.0
                $0.style.flexGrow = 1.0
            }
            contentLayout.children = [titleNote,todosVLayout]
            return ASInsetLayoutSpec(insets: insets, child: contentLayout)
        }
        
        return ASInsetLayoutSpec(insets: insets, child: todosVLayout)
    }
    
    func getTodoTextAttributes(text: String,isChecked:Bool) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        //        paragraphStyle.lineSpacing = 1.2
        
        var attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.cardText,
            .paragraphStyle:paragraphStyle
        ]
        
        if isChecked {
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            attributes[.strikethroughColor] = UIColor.chkCheckedTextColor
            attributes[.foregroundColor] = UIColor.chkCheckedTextColor
        }
        
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    
    func getTitleLabelAttributes(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.cardText,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
}
