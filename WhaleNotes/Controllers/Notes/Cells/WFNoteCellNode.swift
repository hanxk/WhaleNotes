//
//  WFNoteCellNode.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/13.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit

class WFNoteCellNode: ASCellNode {
    
    enum CardUIConstants {
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 10
        static let verticalSpace: CGFloat = 8
    }
    
    var elements:[ASLayoutElement] = []
    
    
    var chkElements:[ASLayoutElement] = []
    var todosElements:[ASLayoutElement] = []
    var imageNodes:[ASImageNode] = []
    
    var emptyTextNode:ASTextNode?
    
    required init(noteInfo:Note) {
        super.init()
        
        
        
        let cornerRadius:CGFloat = 8
        self.borderWidth = 1
        self.cornerRadius = cornerRadius
        self.borderColor = UIColor(hexString: "#e0e0e0").cgColor
        self.backgroundColor = UIColor.init(hexString: "#FAFBFC")
        
        
        
        if  noteInfo.rootBlock.text.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTitleLabelAttributes(text: noteInfo.rootBlock.text)
            titleNode.maximumNumberOfLines = 2
            self.addSubnode(titleNode)
            self.elements.append(titleNode)
        }
        
        if let textBlock = noteInfo.textBlock,textBlock.text.isNotEmpty {
            let textNode = ASTextNode()
            textNode.attributedText = getTextLabelAttributes(text: textBlock.text)
            self.addSubnode(textNode)
            self.elements.append(textNode)
        }
        
        if noteInfo.todoToggleBlocks.isNotEmpty {
            var todoBlocks:[Block] = []
            for toggleBlock in noteInfo.todoToggleBlocks {
                for block in noteInfo.getChildTodoBlocks(parent: toggleBlock.id) {
                    todoBlocks.append(block)
                    if todoBlocks.count == 6 {
                        break
                    }
                }
            }
            addTodoNodes(with: todoBlocks)
        }
        
        if noteInfo.imageBlocks.isNotEmpty {
            self.addImageNodes(with: noteInfo.imageBlocks)
        }
        
        if elements.isEmpty &&  todosElements.isEmpty && imageNodes.count == 0 {
            let textNode = ASTextNode()
            textNode.attributedText = getEmptyTextLabelAttributes(text: "未填写任何内容")
            self.addSubnode(textNode)
            self.emptyTextNode = textNode
        }
    }
    
    private func addTodoNodes(with todoBlocks:[Block]) {
        
        for (_,block) in todoBlocks.enumerated() {
            let imageNode = ASImageNode()
            let config = UIImage.SymbolConfiguration(pointSize:14, weight: .light)
            imageNode.image = UIImage(systemName: block.isChecked ? "checkmark.square" :  "square",withConfiguration: config )?.withTintColor(UIColor.init(hexString: "#999999"))
//            imageNode.style.height = ASDimensionMake(20)
            imageNode.contentMode = .center
//            imageNode.backgroundColor = .red
            self.addSubnode(imageNode)
            self.chkElements.append(imageNode)
            
            
            let todoNode = ASTextNode()
            todoNode.attributedText = getTodoTextAttributes(text: block.text)
            todoNode.style.flexShrink = 1.0
//            todoNode.textContainerInset = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
            todoNode.maximumNumberOfLines = 2
            todoNode.truncationMode = .byTruncatingTail
//            todoNode.backgroundColor = .blue
            self.addSubnode(todoNode)
            self.todosElements.append(todoNode)
        }
        
    }
    
    private func addImageNodes(with imageBlocks:[Block]) {
        
        for imageBlock in imageBlocks.reversed() {
            let imageNode = ASImageNode().then {
                $0.contentMode = .scaleAspectFill
                let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.source).absoluteString
                let image   = UIImage(contentsOfFile: imageUrlPath)
                $0.image = image
                $0.backgroundColor = .placeHolderColor
            }
            self.imageNodes.append(imageNode)
            self.addSubnode(imageNode)
            
            if  self.imageNodes.count == 4 { // 最大显示4张图
                break
            }
            
        }
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stackLayout = ASStackLayoutSpec.vertical()
        stackLayout.justifyContent = .start
        stackLayout.alignItems = .start
        stackLayout.style.flexShrink = 1.0
        
        let contentLayout = ASStackLayoutSpec.vertical()
        contentLayout.spacing = 6
        contentLayout.justifyContent = .start
        contentLayout.alignItems = .start
        contentLayout.style.flexShrink = 1.0
        contentLayout.children = self.elements
        
        
        let insets =  UIEdgeInsets.init(top: CardUIConstants.verticalPadding, left: CardUIConstants.horizontalPadding, bottom: CardUIConstants.verticalPadding, right:  CardUIConstants.horizontalPadding)
        
        if let emptyTextNode = self.emptyTextNode {
            let emptyLayout =  ASInsetLayoutSpec(insets: insets, child: emptyTextNode)
            return emptyLayout
        }
        
        if self.elements.count > 0 {
            contentLayout.children = self.elements
        }
        
        if todosElements.count > 0 {
            let todosVLayout = ASStackLayoutSpec.vertical()
            todosVLayout.justifyContent = .start
            todosVLayout.alignItems = .start
            todosVLayout.style.flexShrink = 1.0
            todosVLayout.spacing = 4
            for i in 0..<todosElements.count {
                
                let todoStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                      spacing: 4,
                                                      justifyContent: .start,
                                                      alignItems: .start,
                                                      children: [chkElements[i],todosElements[i]])
                todoStackSpec.style.flexShrink = 1.0
                todosVLayout.children?.append(todoStackSpec)
            }
            contentLayout.children?.append(todosVLayout)
        }
        
        if let count = contentLayout.children?.count,count > 0 {
            let children =  ASInsetLayoutSpec(insets: insets, child: contentLayout)
            stackLayout.children = [children]
        }
        
        if imageNodes.isNotEmpty {
            let imagesElement = renderImageNodes(constrainedSize:constrainedSize)
            stackLayout.children?.append(imagesElement)
        }
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
               .foregroundColor: UIColor.init(hexString: "#333333"),
               .paragraphStyle:paragraphStyle
           ]
           
           return NSAttributedString(string: text, attributes: attributes)
    }
    
    func getTextLabelAttributes(text: String) -> NSAttributedString {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.4
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15),
            .foregroundColor: UIColor.init(hexString: "#333333"),
            .paragraphStyle:paragraphStyle
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func getEmptyTextLabelAttributes(text: String) -> NSAttributedString {
        let font = UIFont.systemFont(ofSize: 15)
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
        paragraphStyle.lineSpacing = 1.2
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.init(hexString: "#444444"),
            .paragraphStyle:paragraphStyle
        ]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
}
