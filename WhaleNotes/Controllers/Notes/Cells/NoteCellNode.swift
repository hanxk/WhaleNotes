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

class NoteCellNode: ASCellNode {
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 10
        static let verticalPaddingBottom: CGFloat = 4
        static let attachHeigh: CGFloat = 74
        
        static let contentVerticalSpacing: CGFloat = 2
        
        static let todoHeight:CGFloat = 22
        static let todoVSpace:CGFloat = 0
        static let todoTextSpace:CGFloat = 2
        static let todoImageSize: CGFloat = 14
        static let todoTextSize: CGFloat = 14
        
        static let bottomHeight: CGFloat = 30
        
        
        static let imageHeight: CGFloat = 74
    }
    
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
    
    func setupBackBackground() {
        self.backgroundColor = UIColor(hexString: note.backgroundColor)
               if note.backgroundColor.isWhiteHex {
               }
               self.borderWidth = 1
        self.borderColor = UIColor.colorBoarder.cgColor
    }
    
    required init(note:Note,itemSize: CGSize) {
        super.init()
        
        self.note = note
        
        self.setupBackBackground()
        
        let cornerRadius:CGFloat = 6
        self.cornerRadius = cornerRadius
        //        self.borderColor = UIColor(hexString: "#e0e0e0").cgColor
        //        self.borderColor = UIColor(hexString: "#000000").cgColor
       
        //        self.backgroundColor = UIColor.init(hexString: "#FAFAFA")
        
        var titleHeight:CGFloat = 0
        
        let contentWidth = itemSize.width - Constants.horizontalPadding*2
        let contentHeight = itemSize.height - Constants.verticalPadding - Constants.verticalPaddingBottom  -  Constants.bottomHeight
        
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
                $0.backgroundColor = .placeHolderColor
                $0.style.width = ASDimensionMake(contentWidth)
                $0.style.height = ASDimensionMake(Constants.imageHeight)
                
            }
            imageNode.addTarget(self, action: #selector(self.noteCellImageBlockTapped), forControlEvents: .touchUpInside)
            imageNode.cornerRadius = 4
            remainHeight -= Constants.imageHeight
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
                let todoCount = Int(remainHeight / (Constants.todoHeight))
                addTodoNodes(with: todoBlocks,maxCount:todoCount)
                
            }else {
                let textAndTodosHeight =  calculateTextAndTodoMaxHeight(remainHeight: remainHeight, textHeight: textHeight, todos: todoBlocks)
                textNode?.style.maxHeight = ASDimensionMake(textAndTodosHeight.0)
                let todoCount = Int(textAndTodosHeight.1 / Constants.todoHeight)
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
            $0.style.height = ASDimensionMake(Constants.bottomHeight)
            
            let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            let iconImage = UIImage(systemName: "ellipsis", withConfiguration: config)?.withTintColor(UIColor.init(hexString: "#999999"))
            
            $0.setImage(iconImage, for: .normal)
            $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: Constants.horizontalPadding, bottom:0, right: Constants.horizontalPadding)
            $0.contentMode = .center
        }
        
        if self.todosElements.isNotEmpty {
            
            self.menuTodoImage = ASImageNode().then {
                $0.image = UIImage(systemName: "checkmark.square", pointSize: Constants.todoImageSize, weight: .regular)?.withTintColor(UIColor.init(hexString: "#999999"))
                $0.contentMode = .center
            }
            self.addSubnode(self.menuTodoImage!)
            
            self.menuTodoText = ASTextNode().then {
                $0.attributedText = getMenuLabelAttributes(text: "\(todoInfo.0)/\(todoInfo.1)")
            }
            self.addSubnode(self.menuTodoText!)
        }
        
        
        self.addSubnode(menuButton)
        
    }
    
    private func calculateTextAndTodoMaxHeight(remainHeight:CGFloat,textHeight:CGFloat,todos:[Block]) -> (CGFloat,CGFloat) {
        let halfContentHeight = (remainHeight - Constants.contentVerticalSpacing)/2
        let todosHeight = CGFloat(todos.count) * Constants.todoHeight
        
        if halfContentHeight < Constants.todoHeight { // 剩余高度不够，优先展示 todo
            return (remainHeight,0)
        }
        
        if textHeight > halfContentHeight && todosHeight > halfContentHeight { // 各占一半
            let todoHeight = CGFloat(Int(halfContentHeight / Constants.todoHeight)) * Constants.todoHeight
            return (remainHeight - todoHeight,todoHeight)
        }
        
        if textHeight > halfContentHeight {
            let newTextHeight = remainHeight - Constants.contentVerticalSpacing - todosHeight
            return (newTextHeight,todosHeight)
        }
        
        let newTodoHeight = remainHeight - Constants.contentVerticalSpacing - textHeight
        return (halfContentHeight,newTodoHeight)
    }
    
    private func addTodoNodes(with todoBlocks:[Block],maxCount:Int) {
        
        for (index,block) in todoBlocks.enumerated() {
            let imageNode = ASImageNode().then {
                let systemName =  block.isChecked ? "checkmark.square" :  "square"
                $0.image = UIImage(systemName: systemName, pointSize: Constants.todoImageSize, weight: .light)?.withTintColor(UIColor.init(hexString: "#666666"))
                $0.style.height = ASDimensionMake(Constants.todoHeight)
                $0.contentMode = .center
            }
            self.addSubnode(imageNode)
            self.chkElements.append(imageNode)
            
            let todoNode = ASTextNode().then {
                $0.attributedText = getTodoTextAttributes(text: block.text)
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
        
        let cellWidth =  ASDimensionMake(constrainedSize.max.width)
        let cellHeight =  ASDimensionMake(constrainedSize.max.height)
        
        let stackLayout = ASStackLayoutSpec.vertical().then {
            $0.justifyContent = .start
            $0.alignItems = .stretch
            $0.style.width = cellWidth
            $0.style.height = cellHeight
        }
        
        // 内容
        if  let contentLayout = renderContent(constrainedSize: constrainedSize) {
            stackLayout.children?.append(contentLayout)
        }
        
        let isEmptyContent = (stackLayout.children?.count ?? 0) == 0

        let insets =  UIEdgeInsets.init(top: 0 , left: Constants.horizontalPadding, bottom: 0, right:  Constants.horizontalPadding)
        
        // 图片卡
        if isEmptyContent {
            
            let bottomLayout = renderBottomBar(constrainedSize: constrainedSize)
            let bottombarLayout = ASRelativeLayoutSpec(horizontalPosition: .start, verticalPosition: .end, sizingOption: [], child: bottomLayout)
            
            if self.imageNodes.isEmpty {
                
                return bottombarLayout
            }
            
            let imageNode = self.imageNodes[0]
            imageNode.style.width = cellWidth
            imageNode.style.height = cellHeight

            
            let overlayLayout =  ASOverlayLayoutSpec(child: imageNode, overlay: bottombarLayout)
            return overlayLayout
        }
        
        // 添加图片
        if imageNodes.isNotEmpty {
            let imageNode = self.imageNodes[0]
            let children = ASInsetLayoutSpec(insets: insets, child:imageNode)
            stackLayout.children?.append(children)
        }
        
        // bottom bar
        let bottomLayout = renderBottomBar(constrainedSize: constrainedSize)
        stackLayout.children?.append(bottomLayout)
        
        return  stackLayout
    }
    
    private func renderContent(constrainedSize:ASSizeRange) -> ASInsetLayoutSpec? {
        
        
        let insets =  UIEdgeInsets.init(top: Constants.verticalPadding, left: Constants.horizontalPadding, bottom: Constants.verticalPaddingBottom, right:  Constants.horizontalPadding)
        
        let contentHeight = ASDimensionMake(constrainedSize.max.height - Constants.bottomHeight)
        
        let contentLayout = ASStackLayoutSpec.vertical().then {
            $0.spacing = Constants.contentVerticalSpacing
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
            todosVLayout.spacing = Constants.todoVSpace
            for i in 0..<todosElements.count {
                
                let todoStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                      spacing: Constants.todoTextSpace,
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
    
    private func renderBottomBar(constrainedSize:ASSizeRange) -> ASStackLayoutSpec {
        let bottomLayout = ASStackLayoutSpec.horizontal().then {
            $0.style.height = ASDimensionMake(Constants.bottomHeight)
            $0.style.width = ASDimensionMake(constrainedSize.max.width)
            $0.style.flexGrow = 1.0
            $0.justifyContent = .spaceBetween
        }
        let todoStack = ASStackLayoutSpec.horizontal().then {
            $0.spacing = Constants.todoTextSpace
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
        }
        if let menuTodoImage = self.menuTodoImage,
            let menuTodoText = self.menuTodoText {
//            menuTodoImage.backgroundColor = .red
//            menuTodoText.backgroundColor = .red
            let centerTodoText = ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: menuTodoText)
            todoStack.children = [menuTodoImage,centerTodoText]
            
        }
        let todoStackLayout =  ASInsetLayoutSpec(insets: UIEdgeInsets.init(top: 0, left: Constants.horizontalPadding, bottom: 0, right: 0), child: todoStack)

        self.menuButton.addTarget(self, action: #selector(menuButtonTapped), forControlEvents: .touchUpInside)
        bottomLayout.children?.append(todoStackLayout)
        bottomLayout.children?.append(self.menuButton)
        return bottomLayout
    }
    
    @objc func menuButtonTapped(sender:ASImageNode) {
        delegate?.noteCellMenuTapped(sender: sender.view, note: self.note)
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
        paragraphStyle.lineSpacing = 1.8
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.cardText,
        ]
        return NSMutableAttributedString(string: text, attributes: attributes)
    }
    
    func getTextLabelAttributes(text: String) -> NSAttributedString {
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
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
    
    
    func getTodoTextAttributes(text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        //        paragraphStyle.lineSpacing = 1.2
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.cardText,
            .paragraphStyle:paragraphStyle
        ]
        
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


extension NoteCellNode {
    @objc func noteCellImageBlockTapped(sender: ASImageNode) {
        delegate?.noteCellImageBlockTapped(imageView:sender,note:self.note)
    }
}
