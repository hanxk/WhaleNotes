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
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 10
        static let verticalPaddingBottom: CGFloat = 4
        static let attachHeigh: CGFloat = 74
        
        static let contentVerticalSpacing: CGFloat = 2
        
        static let todoHeight:CGFloat = 22
        static let todoVSpace:CGFloat = 0
        
        static let bottomHeight: CGFloat = 26
        
        
        static let imageHeight: CGFloat = 74
    }
    
    var elements:[ASLayoutElement] = []
    
    
    var chkElements:[ASLayoutElement] = []
    var todosElements:[ASLayoutElement] = []
    var imageNodes:[ASImageNode] = []
    
    var titleNode:ASTextNode?
    var textNode:ASTextNode?
    
    var emptyTextNode:ASTextNode?
    
    var menuButton:ASButtonNode!
    
    required init(noteInfo:Note,itemSize: CGSize) {
        super.init()
        
        let cornerRadius:CGFloat = 6
        self.borderWidth = 1
        self.cornerRadius = cornerRadius
//        self.borderColor = UIColor(hexString: "#e0e0e0").cgColor
         self.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.08).cgColor
//        self.borderColor = UIColor(hexString: "#EFF0F1").cgColor
        self.backgroundColor = UIColor.init(hexString: "#FAFBFC")
//        self.backgroundColor = UIColor.init(hexString: "#FAFAFA")
        
        var titleHeight:CGFloat = 0
        
        let contentWidth = itemSize.width - CardUIConstants.horizontalPadding*2
        let contentHeight = itemSize.height - CardUIConstants.verticalPadding - CardUIConstants.verticalPaddingBottom  -  CardUIConstants.bottomHeight
        
        var remainHeight = contentHeight
        
        // 标题
        if  noteInfo.rootBlock.text.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTitleLabelAttributes(text: noteInfo.rootBlock.text)
            titleNode.maximumNumberOfLines = 2
            
            let titlePadding:CGFloat = 4
            titleNode.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: titlePadding, right: 0)
            self.addSubnode(titleNode)
            self.titleNode = titleNode
            
            titleHeight = titleNode.attributedText!.height(containerWidth: contentWidth) + titlePadding
            
            let lineHeight = getTitleLabelAttributes(text: "a").height(containerWidth: contentWidth)
            
            let lineCount = lround(Double(titleHeight / lineHeight)) >= 2 ? 2 : 1
            titleHeight = CGFloat(lineCount) * lineHeight
            
            remainHeight = contentHeight - titleHeight
        }
        
        
        // 图片
        if noteInfo.imageBlocks.isNotEmpty {
            let imageBlock = noteInfo.imageBlocks[0]
            let imageNode = ASImageNode().then {
                $0.contentMode = .scaleAspectFill
                let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.source).absoluteString
                let image   = UIImage(contentsOfFile: imageUrlPath)
                $0.image = image
                $0.backgroundColor = .placeHolderColor
                $0.style.width = ASDimensionMake(contentWidth)
                $0.style.height = ASDimensionMake(CardUIConstants.imageHeight)
                
            }
            imageNode.cornerRadius = 4
            remainHeight -= CardUIConstants.imageHeight
            self.imageNodes.append(imageNode)
            self.addSubnode(imageNode)
        }
        
        
        
        var textHeight:CGFloat = 0
        
        // 文本
        if let textBlock = noteInfo.textBlock,textBlock.text.isNotEmpty {
            
            let textNode = ASTextNode()
            textNode.attributedText = getTextLabelAttributes(text: textBlock.text)
            textNode.truncationMode = .byTruncatingTail
            
            textHeight = textNode.attributedText!.height(containerWidth: contentWidth)
            textNode.style.maxHeight = ASDimensionMake(remainHeight)
            
            self.textNode = textNode
            self.addSubnode(textNode)
        }
        
        // todo
        if noteInfo.todoToggleBlocks.isNotEmpty {
            var todoBlocks:[Block] = []
            for toggleBlock in noteInfo.todoToggleBlocks {
                for block in noteInfo.getChildTodoBlocks(parent: toggleBlock.id) {
                    todoBlocks.append(block)
                    if todoBlocks.count == 10 {
                        break
                    }
                }
            }
            
            if textHeight == 0 {
                let todoCount = Int(remainHeight / (CardUIConstants.todoHeight))
                addTodoNodes(with: todoBlocks,maxCount:todoCount)
                
            }else {
                let textAndTodosHeight =  calculateTextAndTodoMaxHeight(remainHeight: remainHeight, textHeight: textHeight, todos: todoBlocks)
                textNode?.style.maxHeight = ASDimensionMake(textAndTodosHeight.0)
                let todoCount = Int(textAndTodosHeight.1 / CardUIConstants.todoHeight)
                if todoCount > 0 {
                    addTodoNodes(with: todoBlocks,maxCount:todoCount)
                }
            }
            
        }
        
        
        if titleNode == nil && textNode == nil && elements.isEmpty &&  todosElements.isEmpty && imageNodes.count == 0 {
            let textNode = ASTextNode()
            textNode.attributedText = getEmptyTextLabelAttributes(text: "未填写任何内容")
            self.addSubnode(textNode)
            self.emptyTextNode = textNode
        }
        
        menuButton = ASButtonNode().then {
            //            $0.style.width = ASDimensionMake(CardUIConstants.bottomHeight+16)
            $0.style.height = ASDimensionMake(CardUIConstants.bottomHeight)
            
            
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
            let iconImage = UIImage(systemName: "ellipsis", withConfiguration: config)?.withTintColor(UIColor.init(hexString: "#ACADAE"))
            
            $0.setImage(iconImage, for: .normal)
            $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom:0, right: 10)
            $0.contentMode = .center
            //            $0.backgroundColor = .blue
        }
        self.addSubnode(menuButton)
        
    }
    
    private func calculateTextAndTodoMaxHeight(remainHeight:CGFloat,textHeight:CGFloat,todos:[Block]) -> (CGFloat,CGFloat) {
        let halfContentHeight = (remainHeight - CardUIConstants.contentVerticalSpacing)/2
        let todosHeight = CGFloat(todos.count) * CardUIConstants.todoHeight
        
        if halfContentHeight < CardUIConstants.todoHeight { // 剩余高度不够，优先展示 todo
            return (remainHeight,0)
        }
        
        if textHeight > halfContentHeight && todosHeight > halfContentHeight { // 各占一半
            return (halfContentHeight,halfContentHeight)
        }
        
        if textHeight > halfContentHeight {
            let newTextHeight = remainHeight - CardUIConstants.contentVerticalSpacing - todosHeight
            return (newTextHeight,todosHeight)
        }
        
        let newTodoHeight = remainHeight - CardUIConstants.contentVerticalSpacing - textHeight
        return (halfContentHeight,newTodoHeight)
    }
    
    private func addTodoNodes(with todoBlocks:[Block],maxCount:Int) {
        
        for (index,block) in todoBlocks.enumerated() {
            let imageNode = ASImageNode()
            let config = UIImage.SymbolConfiguration(pointSize:14, weight: .light)
            imageNode.image = UIImage(systemName: block.isChecked ? "checkmark.square" :  "square",withConfiguration: config )?.withTintColor(UIColor.init(hexString: "#666666"))
            imageNode.style.height = ASDimensionMake(CardUIConstants.todoHeight)
            imageNode.contentMode = .center
//            imageNode.backgroundColor = .red
            self.addSubnode(imageNode)
            self.chkElements.append(imageNode)
            
            
            let todoNode = ASTextNode()
            todoNode.attributedText = getTodoTextAttributes(text: block.text)
            todoNode.style.flexShrink = 1.0
            todoNode.maximumNumberOfLines = 1
            todoNode.truncationMode = .byTruncatingTail
//            todoNode.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
//                        todoNode.backgroundColor = .blue
            self.addSubnode(todoNode)
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
            let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.source).absoluteString
            let image   = UIImage(contentsOfFile: imageUrlPath)
            $0.image = image
            $0.backgroundColor = .placeHolderColor
        }
        self.imageNodes.append(imageNode)
        self.addSubnode(imageNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stackLayout = ASStackLayoutSpec.vertical()
        stackLayout.justifyContent = .start
        stackLayout.alignItems = .stretch
        stackLayout.style.height = ASDimensionMake(constrainedSize.max.height)
        
        let contentHeight = ASDimensionMake(constrainedSize.max.height - CardUIConstants.bottomHeight)
        
        let contentLayout = ASStackLayoutSpec.vertical().then {
            $0.spacing = CardUIConstants.contentVerticalSpacing
            $0.justifyContent = .start
            $0.alignItems = .start
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.style.height = contentHeight
        }
        
        let bottomLayout = ASStackLayoutSpec.horizontal()
        bottomLayout.style.height = ASDimensionMake(CardUIConstants.bottomHeight)
        bottomLayout.style.width = ASDimensionMake(constrainedSize.max.width)
        
        
        let insets =  UIEdgeInsets.init(top: CardUIConstants.verticalPadding, left: CardUIConstants.horizontalPadding, bottom: CardUIConstants.verticalPaddingBottom, right:  CardUIConstants.horizontalPadding)
        
        if let emptyTextNode = self.emptyTextNode {
            let emptyLayout =  ASInsetLayoutSpec(insets: insets, child: emptyTextNode)
            return emptyLayout
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
            todosVLayout.spacing = CardUIConstants.todoVSpace
            for i in 0..<todosElements.count {
                
                let todoStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                      spacing: 4,
                                                      justifyContent: .start,
                                                      alignItems: .center,
                                                      children: [chkElements[i],todosElements[i]])
                todoStackSpec.style.flexShrink = 1.0
                todosVLayout.children?.append(todoStackSpec)
            }
            contentLayout.children?.append(todosVLayout)
        }
        
        if let count = contentLayout.children?.count,count > 0 {
            let children =  ASInsetLayoutSpec(insets: insets, child: contentLayout)
            children.style.flexShrink = 1.0
            stackLayout.children = [children]
        }
        
        if imageNodes.isNotEmpty {
            let insets =  UIEdgeInsets.init(top: 0 , left: CardUIConstants.horizontalPadding, bottom: 0, right:  CardUIConstants.horizontalPadding)
            let children =  ASInsetLayoutSpec(insets: insets, child: self.imageNodes[0])
            stackLayout.children?.append(children)
        }
        
        
        bottomLayout.style.flexGrow = 1.0
        bottomLayout.justifyContent = .end
        bottomLayout.children?.append(self.menuButton)
        
        // bottom bar
        stackLayout.children?.append(bottomLayout)
        
        return  stackLayout
    }
    
    
    private func renderImageNodes(constrainedSize:ASSizeRange) -> ASLayoutElement {
        let height:CGFloat = 120
        let width:CGFloat = constrainedSize.max.width
        let spacing:CGFloat = 2
        
        let singleWidth = (width - spacing)/2
        let singleHeight = (height - spacing)/2
        
        if imageNodes.count == 1 {
            let imageNode = imageNodes[0]
            imageNode.style.width = ASDimensionMake(constrainedSize.max.width)
            imageNode.style.height = ASDimensionMake(height)
            return imageNode
        }
        
        
        if imageNodes.count == 2 {
            imageNodes.forEach {
                $0.style.width = ASDimensionMake(singleWidth)
                $0.style.height = ASDimensionMake(height)
            }
            let imagesStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                    spacing: spacing,
                                                    justifyContent: .start,
                                                    alignItems: .start,
                                                    children: imageNodes)
            imagesStackSpec.style.flexShrink = 1.0
            return imagesStackSpec
        }
        
        if imageNodes.count == 3 {
            
            
            let imagesStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                    spacing: 2,
                                                    justifyContent: .start,
                                                    alignItems: .start,
                                                    children: [])
            imagesStackSpec.style.flexShrink = 1.0
            
            //左：1
            let imageNode = imageNodes[0]
            imageNode.style.width = ASDimensionMake(singleWidth)
            imageNode.style.height = ASDimensionMake(height)
            //            imageNode.cornerRadius
            
            //右：2
            let twoImageNodes = [imageNodes[1], imageNodes[2]]
            let twoImagesLayout = ASStackLayoutSpec(direction: .vertical,
                                                    spacing: 2,
                                                    justifyContent: .start,
                                                    alignItems: .start,
                                                    children: twoImageNodes)
            twoImagesLayout.style.flexShrink = 1.0
            
            twoImageNodes.forEach {
                $0.style.width = ASDimensionMake(singleWidth)
                $0.style.height = ASDimensionMake(singleHeight)
            }
            
            
            
            imagesStackSpec.children = [imageNode,twoImagesLayout]
            
            return imagesStackSpec
        }
        
        // 4
        
        //左：1
        let leftTwoImagesLayout = ASStackLayoutSpec(direction: .vertical,
                                                    spacing: spacing,
                                                    justifyContent: .start,
                                                    alignItems: .start,
                                                    children:  [imageNodes[0], imageNodes[1]])
        
        //右：2
        let rightTwoImagesLayout = ASStackLayoutSpec(direction: .vertical,
                                                     spacing: spacing,
                                                     justifyContent: .start,
                                                     alignItems: .start,
                                                     children: [imageNodes[2], imageNodes[3]])
        
        imageNodes.forEach {
            $0.style.width = ASDimensionMake(singleWidth)
            $0.style.height = ASDimensionMake(singleHeight)
        }
        
        let imagesStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                spacing: spacing,
                                                justifyContent: .start,
                                                alignItems: .start,
                                                children: [leftTwoImagesLayout,rightTwoImagesLayout])
        return imagesStackSpec
    }
    
    override func didLoad() {
        
    }
    
    func getTitleLabelAttributes(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.4
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor:  UIColor.init(hexString: "#333333"),
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    func getTextLabelAttributes(text: String) -> NSAttributedString {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3

        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.init(hexString: "#333333"),
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
    
    
    func getTodoTextAttributes(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineSpacing = 1.2
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.init(hexString: "#333333"),
            .paragraphStyle:paragraphStyle
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
}
