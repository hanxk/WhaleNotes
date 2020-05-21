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
    
    required init(title:String,text:String,todosRef:ThreadSafeReference<List<Block>>?) {
        super.init()
        
        if  title.isNotEmpty {
            let titleNode = ASTextNode()
            titleNode.attributedText = getTextLabelAttributes(text: title)
            self.addSubnode(titleNode)
            self.elements.append(titleNode)
        }
        if text.isNotEmpty {
            let textNode = ASTextNode()
            textNode.attributedText = getTextLabelAttributes(text: text)
            self.addSubnode(textNode)
            self.elements.append(textNode)
        }
        
        if let todosRef = todosRef {
            let realm = try! Realm()
            guard let todoBlocks = realm.resolve(todosRef) else { return }
            if !todoBlocks.isEmpty {
                addTodoNodes(with: todoBlocks)
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
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let stackLayout = ASStackLayoutSpec.vertical()
        stackLayout.justifyContent = .start
        stackLayout.alignItems = .start
        stackLayout.style.flexShrink = 1.0
        stackLayout.spacing = NoteCardCell.CardUIConstants.verticalSpace
        
        let insets =  UIEdgeInsets.init(top: CardUIConstants.verticalPadding, left: CardUIConstants.horizontalPadding, bottom: CardUIConstants.verticalPadding, right:  CardUIConstants.horizontalPadding)
        
        stackLayout.children = self.elements
        
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

            stackLayout.children?.append(todosVLayout)
        }
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
