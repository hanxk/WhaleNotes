//
//  NoteTitleNode.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit


class NoteTitleCellNode:ASCellNode {
    private(set) lazy var titleNode = ASEditableTextNode().then {
        $0.attributedPlaceholderText = getTitlePlaceHolderAttributesString()
        $0.scrollEnabled = false
        $0.typingAttributes = getTitleAttributesString()
        $0.textContainerInset = UIEdgeInsets(top: 4, left: MDEditorConfig.paddingH, bottom: 8, right: MDEditorConfig.paddingH)
        $0.delegate = self
        $0.textView.tag = EditViewTag.title.rawValue
    }
    private var textChanged: ((String) -> Void)?
    private var textDidFinishEditing: ((String) -> Void)?
    private var textEnterkeyInput: (() -> Void)?
    private var textShouldBeginEditing: ((UITextView) -> Void)?
    
    private(set) var title = ""
    
    init(title:String) {
        super.init()
        self.title = title
        titleNode.attributedText = NSMutableAttributedString(string: title, attributes: getTitleAttributes())
        self.addSubnode(titleNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top:0, left: 0, bottom: 0, right: 0)
        return  ASInsetLayoutSpec(insets: insets, child: titleNode)
    }
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
    
    func textDidFinishEditing(action: @escaping (String) -> Void) {
        self.textDidFinishEditing = action
    }
    func textEnterkeyInput(action: @escaping () -> Void) {
        self.textEnterkeyInput = action
    }
    
    func textShouldBeginEditing(action: @escaping (UITextView) -> Void) {
        self.textShouldBeginEditing = action
    }
}

extension NoteTitleCellNode {
        
    func getTitleAttributesString() -> [String: Any] {
        return Dictionary(uniqueKeysWithValues:
                            getTitleAttributes().map { key, value in (key.rawValue, value) })
    }
    
    func getTitlePlaceHolderAttributesString() -> NSAttributedString {
        var titleAttr = getTitleAttributes()
        titleAttr[.foregroundColor] = UIColor.lightGray
        return NSMutableAttributedString(string: "标题", attributes: titleAttr)
    }
    

    private func getTitleAttributes() -> [NSAttributedString.Key: Any] {
        let font = MDStyle.generateDefaultFont(fontSize: 22,weight: .medium)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.lineBreakMode = .byWordWrapping;
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor:UIColor.cardTitle
        ]
        return attributes
    }
}


extension NoteTitleCellNode: ASEditableTextNodeDelegate {
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let textView = editableTextNode.textView
        let newText = textView.text ??  ""
        self.title = newText
        self.textChanged?(newText)
    }
    
    func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        self.textDidFinishEditing?(text)
    }
    
    func editableTextNodeShouldBeginEditing(_ editableTextNode: ASEditableTextNode) -> Bool {
        self.textShouldBeginEditing?(editableTextNode.textView)
        return true
    }
    
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//       return self.mdHelper?.textView(editableTextNode.textView, shouldChangeTextIn: range, replacementText: text) ?? false
//        let textView = editableTextNode.textView
        if text == "\n" {
            textEnterkeyInput?()
            return  false
        }
        return  true
    }
}
