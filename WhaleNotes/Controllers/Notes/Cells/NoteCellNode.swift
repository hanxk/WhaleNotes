//
//  NoteCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit


protocol NoteCellNodeDelegate:AnyObject {
    func noteCellImageBlockTapped(imageView:ASImageNode,note:Note)
    func noteCellMenuTapped(sender:UIView,note:Note)
}

enum NoteCellConstants {
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
    
    static let bottomHeight: CGFloat = 30
    
    static let boardHeight: CGFloat = 32
    
    static let imageHeight: CGFloat = 74
}

class NoteCellNode: ASCellNode {
    
    
    weak var delegate:NoteCellNodeDelegate?
    
    var elements:[ASLayoutElement] = []
    
    
    var chkElements:[ASLayoutElement] = []
    var todosElements:[ASLayoutElement] = []
    var imageNodes:[ASImageNode] = []
    
    var titleNode:ASTextNode?
    var textNode:ASTextNode?
    
    var emptyTextNode:ASTextNode?
    
    var menuButton:ASButtonNode!
    var menuTodoImage:ASImageNode?
    var menuTodoText:ASTextNode?
    
    var note:Note!
    
    var cardbackground:ASDisplayNode!
    
    var callbackBoardButtonTapped:((Note)->Void)?
    
    
    var boardButton:ASButtonNode?
    
    var itemSize:CGSize!
    
    func setupBackBackground() {
        self.cardbackground.backgroundColor = UIColor(hexString: note.backgroundColor)
        if note.backgroundColor.isWhiteHex {
            self.cardbackground.borderColor = UIColor.colorBoarder.cgColor
        }else {
            self.cardbackground.borderColor = UIColor.colorBoarder2.cgColor
        }
    }
    
    required init(note:Note,itemSize: CGSize,isShowBoard:Bool = false) {
        super.init()
        
        self.itemSize = itemSize
        
        self.note = note
        
        let cornerRadius:CGFloat = 6
        self.cornerRadius = cornerRadius
        
        cardbackground = ASDisplayNode().then {
            $0.backgroundColor = UIColor(hexString: note.backgroundColor)
            $0.borderWidth = 1
            if note.backgroundColor.isWhiteHex {
                $0.borderColor = UIColor.colorBoarder.cgColor
            }else {
                $0.borderColor = UIColor.colorBoarder2.cgColor
            }
            $0.cornerRadius = cornerRadius
        }
        self.addSubnode(cardbackground)
        
        
        var titleHeight:CGFloat = 0
        
        let contentWidth = itemSize.width - NoteCellConstants.horizontalPadding*2
        let contentHeight = itemSize.height - NoteCellConstants.verticalPadding - NoteCellConstants.verticalPaddingBottom  -  NoteCellConstants.bottomHeight
        
        var remainHeight = contentHeight
        
        
        
        // 标题
        if  note.rootBlock.text.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTitleLabelAttributes(text: note.rootBlock.text)
            
            let titlePadding:CGFloat = 2
            titleNode.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: titlePadding, right: 0)
            self.addSubnode(titleNode)
            self.titleNode = titleNode
            
            if note.todoBlocks.isEmpty && (note.textBlock?.text ?? "").isEmpty {
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
        if note.imageBlocks.isNotEmpty {
            let imageBlock = note.imageBlocks[0]
            let imageNode = ASImageNode().then {
                $0.contentMode = .scaleAspectFill
                let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.source).absoluteString
                let image   = UIImage(contentsOfFile: imageUrlPath)
                $0.image = image
                $0.backgroundColor = UIColor.placeHolderColor.withAlphaComponent(0.6)
                $0.style.width = ASDimensionMake(contentWidth)
                $0.style.height = ASDimensionMake(NoteCellConstants.imageHeight)
                $0.addTarget(self, action: #selector(self.noteCellImageBlockTapped), forControlEvents: .touchUpInside)
                $0.cornerRadius = cornerRadius
                $0.borderWidth = 1
                $0.borderColor = cardbackground.borderColor
                
            }
            remainHeight -= NoteCellConstants.imageHeight
            self.imageNodes.append(imageNode)
            self.addSubnode(imageNode)
        }
        
        
        
        
        var textHeight:CGFloat = 0
        
        // 文本
        if let textBlock = note.textBlock,textBlock.text.isNotEmpty {
            
            let textNode = ASTextNode()
            textNode.attributedText = getTextLabelAttributes(text: textBlock.text)
            textNode.truncationMode = .byTruncatingTail
            
            textHeight = textNode.attributedText!.height(containerWidth: contentWidth)
            textNode.style.maxHeight = ASDimensionMake(remainHeight)
            //            textNode.backgroundColor = .red
            
            self.textNode = textNode
            self.addSubnode(textNode)
        }
        
        // todo
        var todoInfo:(Int,Int) = (0,0)
        let todoBlocks = note.todoBlocks
        if todoBlocks.isNotEmpty {
            
            for todoBlock  in todoBlocks {
                if todoBlock.isChecked {
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
        
        
        if titleNode == nil && textNode == nil && elements.isEmpty &&  todosElements.isEmpty && imageNodes.count == 0 {
            let textNode = ASTextNode()
            textNode.attributedText = getEmptyTextLabelAttributes(text: "未填写任何内容")
            self.addSubnode(textNode)
            self.emptyTextNode = textNode
        }
        
        menuButton = ASButtonNode().then {
            $0.style.height = ASDimensionMake(NoteCellConstants.bottomHeight)
            $0.style.width = ASDimensionMake(NoteCellConstants.bottomHeight)
            
//            $0.setImage(UIImage(systemName: "ellipsis", pointSize: 15)!.withTintColor(UIColor(hexString: "#999999")), for: .normal)
//            $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: NoteCellConstants.horizontalPadding, bottom:0, right: NoteCellConstants.horizontalPadding)
            $0.contentMode = .center
            $0.addTarget(self, action: #selector(menuButtonTapped), forControlEvents: .touchUpInside)
            $0.cornerRadius = 4
        }
        
        if self.todosElements.isNotEmpty {
            
            self.menuTodoImage = ASImageNode().then {
                $0.image = UIImage(systemName: "text.badge.checkmark", pointSize: 13, weight: .medium)?.withTintColor(UIColor(hexString: "#999999"))
                $0.contentMode = .center
            }
            self.addSubnode(self.menuTodoImage!)
            
            self.menuTodoText = ASTextNode().then {
                $0.attributedText = getMenuLabelAttributes(text: "\(todoInfo.0)/\(todoInfo.1)")
            }
            self.addSubnode(self.menuTodoText!)
        }
        
        if isShowBoard {
            let boardButton = ASButtonNode().then {
                $0.style.height = ASDimensionMake(NoteCellConstants.boardHeight)
                $0.style.width = ASDimensionMake(itemSize.width)
//                $0.backgroundColor = .red
                $0.contentHorizontalAlignment = .left
                
                let horizontalPadding:CGFloat = 2
                $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: horizontalPadding, bottom:0, right: horizontalPadding)
                
                $0.setAttributedTitle(getBoardButtonAttributesText(text: note.boards[0].title), for: .normal)
                $0.addTarget(self, action: #selector(boardButtonTapped), forControlEvents: .touchUpInside)
            }
            self.boardButton = boardButton
            self.addSubnode(boardButton)
        }
        
        
        self.addSubnode(menuButton)
        
    }
    
    private func calculateTextAndTodoMaxHeight(remainHeight:CGFloat,textHeight:CGFloat,todos:[Block]) -> (CGFloat,CGFloat) {
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
    
    private func addTodoNodes(with todoBlocks:[Block],maxCount:Int) {
        
        for (index,block) in todoBlocks.enumerated() {
            let imageNode = ASImageNode().then {
                let systemName =  block.isChecked ? "checkmark.square" :  "square"
                let chkColor = UIColor.primaryText
                $0.image = UIImage(systemName: systemName, pointSize: NoteCellConstants.todoImageSize, weight: .ultraLight)?.withTintColor(chkColor)
                $0.style.height = ASDimensionMake(NoteCellConstants.todoHeight)
//                $0.style.width = 14
                $0.contentMode = .left
//                $0.backgroundColor = .red
            }
            self.addSubnode(imageNode)
            self.chkElements.append(imageNode)
            
            let todoNode = ASTextNode().then {
                $0.attributedText = getTodoTextAttributes(text: block.text,isChecked: block.isChecked)
                $0.style.flexShrink = 1.0
                $0.maximumNumberOfLines = 1
                $0.truncationMode = .byTruncatingTail
            }
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
        
        let cellWidth =  ASDimensionMake(itemSize.width)
        let cellHeight =  ASDimensionMake(itemSize.height)
        
        let stackLayout = ASStackLayoutSpec.vertical().then {
            $0.justifyContent = .start
            $0.alignItems = .stretch
            $0.style.width = cellWidth
            $0.style.height = cellHeight
        }
        
        
        // 内容
        if  let contentLayout = renderContent() {
            stackLayout.children?.append(contentLayout)
        }
        
        let isEmptyContent = (stackLayout.children?.count ?? 0) == 0
        
        let insets =  UIEdgeInsets.init(top: 0 , left: NoteCellConstants.horizontalPadding, bottom: 0, right:  NoteCellConstants.horizontalPadding)
        
        
        let itemLayout =  ASBackgroundLayoutSpec(child: stackLayout, background: self.cardbackground)
        let bottomLayout = renderBottomBar(isImageCard: self.imageNodes.isNotEmpty && titleNode == nil)
        
        // 图片卡
        if isEmptyContent {
            let bottombarLayout = ASRelativeLayoutSpec(horizontalPosition: .start, verticalPosition: .end, sizingOption: [], child: bottomLayout)
            if self.imageNodes.isEmpty {
                stackLayout.child = bottombarLayout
                return itemLayout
            }
            
            
            let imageNode = self.imageNodes[0]
            imageNode.style.width = ASDimensionMake(itemSize.width)
            imageNode.style.height = ASDimensionMake(itemSize.height)
            
            let overlayLayout =  ASOverlayLayoutSpec(child: imageNode, overlay: bottombarLayout)
            stackLayout.child = overlayLayout
            
            return itemLayout
        }
        
        // 添加图片
        if imageNodes.isNotEmpty {
            let imageNode = self.imageNodes[0]
            let children = ASInsetLayoutSpec(insets: insets, child:imageNode)
            stackLayout.children?.append(children)
        }
        
        
        stackLayout.children?.append(bottomLayout)
        
        if let boardButton = self.boardButton {
            let stackVLayout = ASStackLayoutSpec.vertical().then {
                $0.style.width = cellWidth
            }
            stackVLayout.children = [itemLayout,boardButton]
            return stackVLayout
        }
        return itemLayout
    }
    
    private func renderContent() -> ASInsetLayoutSpec? {
        let insets =  UIEdgeInsets.init(top: NoteCellConstants.verticalPadding, left: NoteCellConstants.horizontalPadding, bottom: NoteCellConstants.verticalPaddingBottom, right:  NoteCellConstants.horizontalPadding)
        
        let contentHeight = ASDimensionMake(itemSize.height - NoteCellConstants.bottomHeight)
        
        let contentLayout = ASStackLayoutSpec.vertical().then {
            $0.spacing = NoteCellConstants.contentVerticalSpacing
            $0.justifyContent = .start
            $0.alignItems = .start
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.style.height = contentHeight
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
        
        let contentCount = contentLayout.children?.count ?? 0
        if contentCount > 0 {
            let children =  ASInsetLayoutSpec(insets: insets, child: contentLayout)
            children.style.flexShrink = 1.0
            return children
        }
        return nil
    }
    
    private func renderBottomBar(isImageCard:Bool = false) -> ASLayoutSpec {
        let bottomLayout = ASStackLayoutSpec.horizontal().then {
            $0.style.height = ASDimensionMake(NoteCellConstants.bottomHeight)
            $0.style.width = ASDimensionMake(itemSize.width)
            $0.style.flexGrow = 1.0
            $0.justifyContent = .spaceBetween
        }
        let todoStack = ASStackLayoutSpec.horizontal().then {
            $0.spacing = NoteCellConstants.todoTextSpace
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
        }
        if let menuTodoImage = self.menuTodoImage,
            let menuTodoText = self.menuTodoText {
            let centerTodoText = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: menuTodoText)
            todoStack.children = [menuTodoImage,centerTodoText]
        }
        if isImageCard {
            self.menuButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            self.menuButton.setImage(UIImage(systemName: "ellipsis", pointSize: 16)!.withTintColor(UIColor.white.withAlphaComponent(0.7)), for: .normal)
        }else {
            self.menuButton.backgroundColor = .clear
            self.menuButton.setImage(UIImage(systemName: "ellipsis", pointSize: 16)!.withTintColor(UIColor(hexString: "#999999")), for: .normal)
        }
        bottomLayout.children?.append(todoStack)
        bottomLayout.children?.append(self.menuButton)
        let rootStackLayout =  ASInsetLayoutSpec(insets: UIEdgeInsets.init(top: 0, left: NoteCellConstants.horizontalPadding, bottom: 0, right: 4), child: bottomLayout)
        return rootStackLayout
    }
    
    @objc func menuButtonTapped(sender:ASImageNode) {
        delegate?.noteCellMenuTapped(sender: sender.view, note: self.note)
    }
    
    @objc func boardButtonTapped() {
        self.callbackBoardButtonTapped?(self.note)
    }
    
    
    override func didLoad() {
        
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
    
    
    func getBoardButtonAttributesText(text: String) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor:  UIColor.init(hexString: "#666666"),
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    
}


extension NoteCellNode {
    @objc func noteCellImageBlockTapped(sender: ASImageNode) {
        delegate?.noteCellImageBlockTapped(imageView:sender,note:self.note)
    }
}
