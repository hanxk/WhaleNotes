//
//  NoteCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit
import RealmSwift

class NoteCellNode: ASCellNode {
    
    enum CardUIConstants {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 8
        static let verticalSpace: CGFloat = 8
    }
    
    var elements:[ASLayoutElement] = []
    
    
    var chkElements:[ASLayoutElement] = []
    var todosElements:[ASLayoutElement] = []
    var imageNodes:[ASImageNode] = []
    
    required init(noteContent:NoteContent) {
        super.init()
        
        if  noteContent.title.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTextLabelAttributes(text: noteContent.title)
            self.addSubnode(titleNode)
            self.elements.append(titleNode)
        }
        if noteContent.text.isNotEmpty {
            let textNode = ASTextNode()
            textNode.attributedText = getTextLabelAttributes(text: noteContent.text)
            self.addSubnode(textNode)
            self.elements.append(textNode)
        }
        
        if let todosRef = noteContent.todosRef {
            let realm = try! Realm()
            guard let todoBlocks = realm.resolve(todosRef) else { return }
            if !todoBlocks.isEmpty {
                addTodoNodes(with: todoBlocks)
            }
        }
        
        if let imagesRef = noteContent.imagesRef {
            let realm = try! Realm()
            guard let imageBlocks = realm.resolve(imagesRef) else { return }
            if !imageBlocks.isEmpty {
                addImageNodes(with: imageBlocks)
            }
        }
        
    }
    
    private func addTodoNodes(with todoBlocks:List<Block>) {
        
        for (_,blockg) in todoBlocks.enumerated() {
            
            if blockg.blocks.isEmpty {
                continue
            }
            
            for block in  blockg.blocks {
                let imageNode = ASImageNode()
                imageNode.image = UIImage(systemName: block.isChecked ? "checkmark.square" :  "square"  )
                imageNode.contentMode = .scaleAspectFill
                self.addSubnode(imageNode)
                self.chkElements.append(imageNode)
                
                
                let todoNode = ASTextNode()
                todoNode.attributedText = getTextLabelAttributes(text: block.text)
                todoNode.style.flexShrink = 1.0
                todoNode.maximumNumberOfLines = 2
                self.addSubnode(todoNode)
                self.todosElements.append(todoNode)
                
                if self.todosElements.count == 6 {
                    break
                }
            }
        }
        
    }
    
    private func addImageNodes(with imageBlocks:List<Block>) {
        
        for (index,imageBlock) in imageBlocks.enumerated() {
            let imageNode = ASImageNode().then {
                $0.contentMode = .scaleAspectFill
                let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.source).absoluteString
                let image   = UIImage(contentsOfFile: imageUrlPath)
                $0.image = image
            }
            self.imageNodes.append(imageNode)
            self.addSubnode(imageNode)
            
            if index == 4 { // 最大显示4张图
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
        contentLayout.spacing = NoteCardCell.CardUIConstants.verticalSpace
        contentLayout.justifyContent = .start
        contentLayout.alignItems = .start
        contentLayout.style.flexShrink = 1.0
        contentLayout.children = self.elements
        
        if self.elements.count > 0 {
            contentLayout.children = self.elements
        }
        
        if todosElements.count > 0 {
            let todosVLayout = ASStackLayoutSpec.vertical()
            todosVLayout.justifyContent = .start
            todosVLayout.alignItems = .start
            todosVLayout.style.flexShrink = 1.0
            todosVLayout.spacing = 2
            for i in 0..<todosElements.count {
                
                let todoStackSpec = ASStackLayoutSpec(direction: .horizontal,
                                                      spacing: 2,
                                                      justifyContent: .start,
                                                      alignItems: .start,
                                                      children: [chkElements[i],todosElements[i]])
                todoStackSpec.style.flexShrink = 1.0
                todosVLayout.children?.append(todoStackSpec)
            }
            contentLayout.children?.append(todosVLayout)
        }
        
        if let count = contentLayout.children?.count,count > 0 {
            let insets =  UIEdgeInsets.init(top: CardUIConstants.verticalPadding, left: CardUIConstants.horizontalPadding, bottom: CardUIConstants.verticalPadding, right:  CardUIConstants.horizontalPadding)
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
    
    func getTodoTextAttributes(text: String) -> NSAttributedString {
        
        let font = UIFont.systemFont(ofSize: 15)
        let fullString = NSMutableAttributedString()
        
        // create our NSTextAttachment
        //        let image1Attachment = NSTextAttachment()
        //        image1Attachment.image = UIImage(systemName: "checkmark.square")
        
        //        let paragraphStyle = NSMutableParagraphStyle()
        //        paragraphStyle.maximumLineHeight = 2
        //        let attributes: [NSAttributedString.Key: Any] = [
        //            .font: font,
        //            .foregroundColor: UIColor.blue,
        //            .paragraphStyle: paragraphStyle
        //        ]
        
        // wrap the attachment in its own attributed string so we can append it
        //        let image1String = NSAttributedString(string: <#T##String#>)
        
        // add the NSTextAttachment wrapper to our full string, then add some more text.
        //        fullString.append(image1String)
        fullString.append(NSAttributedString(string:text))
        
        fullString.addAttribute(NSAttributedString.Key.font, value:font, range: NSMakeRange(0,fullString.length))
        return fullString
    }
    
}
