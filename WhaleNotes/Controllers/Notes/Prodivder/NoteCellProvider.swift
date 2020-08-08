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
    func attach(cell:ASCellNode,contentSize: CGSize)
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec
}


enum NoteCellConstants {
    
    static  let cornerRadius:CGFloat = 8
    
    static let horizontalPadding: CGFloat = 10
    static let verticalPadding: CGFloat = 10
    static let verticalPaddingBottom: CGFloat = 4
    static let attachHeigh: CGFloat = 74
    
    static let contentVerticalSpacing: CGFloat = 2
    
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
    private var chkElements:[ASLayoutElement] = []
    private var todosElements:[ASLayoutElement] = []
    private var imageNodes:[ASImageNode] = []
    private var titleNode:ASTextNode?
    private var textNode:ASTextNode?
    
    
    var menuTodoImage:ASImageNode?
    var menuTodoText:ASTextNode?
    
    private let cornerRadius:CGFloat = 6
    
    
    private var cell:ASCellNode!
    private var noteInfo:NoteInfo!
    private var contentSize:CGSize!
    
    
    init(noteInfo: NoteInfo) {
        self.noteInfo = noteInfo
    }
    
    func attach(cell:ASCellNode,contentSize: CGSize) {
        self.cell = cell
        self.contentSize = contentSize
        
        var titleHeight:CGFloat = 0
        
        let contentWidth = contentSize.width - NoteCellConstants.horizontalPadding*2
        let contentHeight = contentSize.height - NoteCellConstants.verticalPadding - NoteCellConstants.verticalPaddingBottom  -  NoteCellConstants.bottomHeight
        
        var remainHeight = contentHeight
        
        // 标题
        let title = noteInfo.properties.title
        if title.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTitleLabelAttributes(text: title)

            let titlePadding:CGFloat = 2
            titleNode.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: titlePadding, right: 0)
            cell.addSubnode(titleNode)
            self.titleNode = titleNode


            let isTodoExists =  noteInfo.todoGroupBlock?.contentBlocks.isNotEmpty ==  true
            let isTextExists =  noteInfo.textBlock?.blockTextProperties?.title.isNotEmpty == true
            
            
            if !isTodoExists && !isTextExists {
                titleHeight = contentHeight
            }else {
                titleHeight = titleNode.attributedText!.height(containerWidth: contentWidth) + titlePadding
                let lineHeight = getTitleLabelAttributes(text: "a").height(containerWidth: contentWidth)
                let lineCount = lround(Double(titleHeight / lineHeight)) >= 2 ? 2 : 1
                titleHeight = CGFloat(lineCount) * lineHeight + titlePadding
            }
            titleNode.style.height = ASDimensionMake(titleHeight)

            remainHeight = contentHeight - titleHeight
        }
        
        
        // 图片
        if let attachmentGroupBlock = noteInfo.attachmentGroupBlock,attachmentGroupBlock.contentBlocks.isNotEmpty {
            let imageBlock = attachmentGroupBlock.contentBlocks[0]
            let imageNode = ASImageNode().then {
                $0.contentMode = .scaleAspectFill
                let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.blockImageProperties!.url).absoluteString
                let image   = UIImage(contentsOfFile: imageUrlPath)
                $0.image = image
                $0.backgroundColor = UIColor.placeHolderColor.withAlphaComponent(0.6)
                $0.style.width = ASDimensionMake(contentWidth)
                $0.style.height = ASDimensionMake(NoteCellConstants.imageHeight)
//                $0.addTarget(self, action: #selector(self.noteCellImageBlockTapped), forControlEvents: .touchUpInside)
                $0.cornerRadius = cornerRadius
                $0.borderWidth = 1
//                $0.borderColor = cardbackground.borderColor

            }
            remainHeight -= NoteCellConstants.imageHeight
            self.imageNodes.append(imageNode)
            cell.addSubnode(imageNode)
        }
        
        
        
        
        var textHeight:CGFloat = 0
        
        // 文本
        if let textBlock = noteInfo.textBlock,let textProperties = textBlock.blockTextProperties {

            let textNode = ASTextNode()
            textNode.attributedText = getTextLabelAttributes(text: textProperties.title)
            textNode.truncationMode = .byTruncatingTail

            textHeight = textNode.attributedText!.height(containerWidth: contentWidth)
            textNode.style.maxHeight = ASDimensionMake(remainHeight)
            //            textNode.backgroundColor = .red

            self.textNode = textNode
            cell.addSubnode(textNode)
        }
        
        // todo
        var todoInfo:(Int,Int) = (0,0)
        if let todoGroupBlock = noteInfo.todoGroupBlock,todoGroupBlock.contentBlocks.isNotEmpty {
            
            let todoBlocks = todoGroupBlock.contentBlocks
            
            for todoBlock  in todoBlocks {
                if todoBlock.blockTodoProperties!.isChecked {
                    todoInfo.0 = todoInfo.0 + 1
                }
                todoInfo.1 = todoInfo.1 + 1
            }
            
            if textHeight == 0 {
                let todoCount = Int(remainHeight / (NoteCellConstants.todoHeight))
                addTodoNodes(with: todoBlocks,maxCount:todoCount)

            }else {
                let textAndTodosHeight =  calculateTextAndTodoMaxHeight(remainHeight: remainHeight, textHeight: textHeight, todos: todoBlocks)
                textNode?.style.maxHeight = ASDimensionMake(textAndTodosHeight.0)
                let todoCount = Int(textAndTodosHeight.1 / NoteCellConstants.todoHeight)
                if todoCount > 0 {
                    addTodoNodes(with: todoBlocks,maxCount:todoCount)
                }
            }
        }
        
        if self.todosElements.isNotEmpty {
            
            self.menuTodoImage = ASImageNode().then {
                $0.image = UIImage(systemName: "text.badge.checkmark", pointSize: 13, weight: .medium)?.withTintColor(UIColor(hexString: "#999999"))
                $0.contentMode = .center
            }
            cell.addSubnode(self.menuTodoImage!)
            
            self.menuTodoText = ASTextNode().then {
                $0.attributedText = getMenuLabelAttributes(text: "\(todoInfo.0)/\(todoInfo.1)")
            }
            cell.addSubnode(self.menuTodoText!)
        }
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets =  UIEdgeInsets.init(top: NoteCellConstants.verticalPadding, left: NoteCellConstants.horizontalPadding, bottom: NoteCellConstants.verticalPaddingBottom, right:  NoteCellConstants.horizontalPadding)
        
        let contentLayout = ASStackLayoutSpec.vertical().then {
            $0.spacing = NoteCellConstants.contentVerticalSpacing
            $0.style.flexShrink = 1.0
            $0.style.flexGrow = 1.0
        }
        
        if let titleNode = titleNode {
            contentLayout.children?.append(titleNode)
        }
        
        if let textNode = textNode {
            contentLayout.children?.append(textNode)
        }
        
        
        if todosElements.count > 0 {
            let todosVLayout = ASStackLayoutSpec.vertical()
            todosVLayout.justifyContent = .start
            todosVLayout.alignItems = .start
            todosVLayout.style.flexShrink = 1.0
            todosVLayout.spacing = NoteCellConstants.todoVSpace
            for i in 0..<todosElements.count {
                
                let todoStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                      spacing: NoteCellConstants.todoTextSpace,
                                                      justifyContent: .start,
                                                      alignItems: .center,
                                                      children: [chkElements[i],todosElements[i]])
                todoStackSpec.style.flexShrink = 1.0
                todosVLayout.children?.append(todoStackSpec)
            }
            contentLayout.children?.append(todosVLayout)
        }
        return ASInsetLayoutSpec(insets: insets, child: contentLayout)
    }
    
}

extension NoteCellProvider {
    
    private func calculateTextAndTodoMaxHeight(remainHeight:CGFloat,textHeight:CGFloat,todos:[BlockInfo]) -> (CGFloat,CGFloat) {
        let halfContentHeight = (remainHeight - NoteCellConstants.contentVerticalSpacing)/2
        let todosHeight = CGFloat(todos.count) * NoteCellConstants.todoHeight
        
        if halfContentHeight < NoteCellConstants.todoHeight { // 剩余高度不够，优先展示 todo
            return (remainHeight,0)
        }
        
        if textHeight > halfContentHeight && todosHeight > halfContentHeight { // 各占一半
            let todoHeight = CGFloat(Int(halfContentHeight / NoteCellConstants.todoHeight)) * NoteCellConstants.todoHeight
            return (remainHeight - todoHeight,todoHeight)
        }
        
        if textHeight > halfContentHeight {
            let newTextHeight = remainHeight - NoteCellConstants.contentVerticalSpacing - todosHeight
            return (newTextHeight,todosHeight)
        }
        
        let newTodoHeight = remainHeight - NoteCellConstants.contentVerticalSpacing - textHeight
        return (halfContentHeight,newTodoHeight)
    }
    
    private func addTodoNodes(with todoBlocks:[BlockInfo],maxCount:Int) {
        
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
                $0.attributedText = getTodoTextAttributes(text: block.blockTodoProperties!.title,isChecked: block.blockTodoProperties!.isChecked)
                $0.style.flexShrink = 1.0
                $0.maximumNumberOfLines = 1
                $0.truncationMode = .byTruncatingTail
            }
            cell.addSubnode(todoNode)
            self.todosElements.append(todoNode)
            
            if index == maxCount - 1 {
                break
            }
        }
        
    }
    
    private func addImageNodes(with imageBlocks:[Block]) {
        let imageBlock = imageBlocks[0]
        let imageNode = ASImageNode().then {
            $0.contentMode = .scaleAspectFill
            let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.blockImageProperties!.url).absoluteString
            let image   = UIImage(contentsOfFile: imageUrlPath)
            $0.image = image
            $0.backgroundColor = .placeHolderColor
        }
        self.imageNodes.append(imageNode)
        cell.addSubnode(imageNode)
    }
}


extension NoteCellProvider {
    
    func getTitleLabelAttributes(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.8
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.cardText,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    func getTextLabelAttributes(text: String) -> NSAttributedString {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.cardText,
            .paragraphStyle:paragraphStyle
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString
    }
    
    func getEmptyTextLabelAttributes(text: String) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 14)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.0
        paragraphStyle.lineHeightMultiple = 0.8
        let attrString = NSMutableAttributedString()
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.init(hexString: "#999999")
        ]
        attrString.append(NSMutableAttributedString(string:text,attributes: attributes))
        return attrString
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
    
    
    func getMenuLabelAttributes(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor:  UIColor.init(hexString: "#999999"),
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
}
