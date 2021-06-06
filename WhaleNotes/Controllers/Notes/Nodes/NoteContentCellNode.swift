//
//  NoteContentCellNode.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/24.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit


class NoteContentCellNode:ASCellNode {
    
    var textNode:ASEditableTextNode!
    var mdTextViewWrapper:MDTextViewWapper!
    
    private(set) var content:String  = ""
    
    private var textChanged: ((String) -> Void)?
    private var textDidFinishEditing: ((String) -> Void)?
    private var textShouldBeginEditing: ((UITextView) -> Void)?
    private var saveButtonTapped: (() -> Void)?
    
    
    private var mdHelper:MDHelper!
    
    private lazy var keyboardView = MDKeyboardView().then {
        $0.delegate = self
    }
    
    init(title:String) {
        super.init()
        self.content = title
        
        self.textNode =  generateASEditableTextNode(content: title)
        self.textNode.textView.inputAccessoryView = keyboardView
        
//        self.backgroundColor   = .red
        self.addSubnode(textNode)
        
        
        let mdTextViewWrapper = MDTextViewWapper(textView: textNode.textView,isEditable: true)
        mdTextViewWrapper.textviewTappedDelegate =  self
        self.mdTextViewWrapper = mdTextViewWrapper
        
        self.textChanged?(title)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top:0, left: MDEditorConfig.paddingH, bottom: 0, right: MDEditorConfig.paddingH)
        return  ASInsetLayoutSpec(insets: insets, child: textNode)
    }
    
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
    func textDidFinishEditing(action: @escaping (String) -> Void) {
        self.textDidFinishEditing = action
    }
    func textShouldBeginEditing(action: @escaping (UITextView) -> Void) {
        self.textShouldBeginEditing = action
    }
    func saveButtonTapped(action: @escaping () -> Void) {
        self.saveButtonTapped = action
    }
    
    func generateASEditableTextNode(content:String)  -> ASEditableTextNode {
        
        let style = MDStyle(fontSize: 16)
        
        let textStorage =  MarkdownTextStorage(style: style)
        let layoutManager = MyLayoutManger()
                
        let textKitComponents: ASTextKitComponents =
                    .init(textStorage: textStorage,
                          textContainerSize: .zero,
                          layoutManager: layoutManager)
                
        let placeholderTextKit: ASTextKitComponents =
                    .init(attributedSeedString:  getContentPlaceHolderAttributesString(),
                          textContainerSize: .zero)
        
                
        let contentNode = ASEditableTextNode.init(textKitComponents: textKitComponents,
                                           placeholderTextKitComponents: placeholderTextKit).then {
                        $0.placeholderEnabled  = true
                        $0.scrollEnabled = false
                        $0.textView.isEditable =   true
                        $0.typingAttributes = getContentAttributesString()
                        $0.delegate = self
                        $0.textView.tag = EditViewTag.content.rawValue
                        $0.tintColor =  UIColor.cursor
         }
        
        
        contentNode.attributedText =  NSMutableAttributedString(string: content, attributes: style.mdDefaultAttributes)
        
        return  contentNode
    }
}

extension NoteContentCellNode:MDTextViewTappedDelegate {
    func textViewTagTapped(_ textView: UITextView, tag: String) {
        
    }
 
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let view = mdTextViewWrapper.hitTest(self.convert(point, to: textNode), with: event)
           {
            return view
        }
        return super.hitTest(point, with: event)
    }
}

extension NoteContentCellNode: ASEditableTextNodeDelegate {
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let textView = editableTextNode.textView
        
        let newText = textView.text ??  ""
        self.textChanged?(newText)
      
    }
    func editableTextNodeShouldBeginEditing(_ editableTextNode: ASEditableTextNode) -> Bool {
//        let newText = editableTextNode.textView.text ??  ""
        self.textShouldBeginEditing?(editableTextNode.textView)
        return true
    }
    
    func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        self.textDidFinishEditing?(text)
    }
    
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let textView = editableTextNode.textView
        if text == "\n" {
            return self.mdTextViewWrapper.handleEnterkey(textView, shouldChangeTextIn: range, replacementText: text)
        }
        return true
    }
    
}


extension NoteContentCellNode {
        
    func getContentAttributesString() -> [String: Any] {
        return Dictionary(uniqueKeysWithValues:
                            getContentAttributes().map { key, value in (key.rawValue, value) })
    }
    
    func getContentPlaceHolderAttributesString() -> NSAttributedString {
        var titleAttr = getContentAttributes()
        titleAttr[.foregroundColor] = UIColor.lightGray
        return NSMutableAttributedString(string: "写点什么...", attributes: titleAttr)
    }
    

    private func getContentAttributes() -> [NSAttributedString.Key: Any] {
        return  MarkdownAttributes.mdDefaultAttributes
    }
}

extension NoteContentCellNode:UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
    }
}

extension NoteContentCellNode:MDKeyboarActionDelegate {
    func headerButtonTapped() {
        
    }
    
    func tagButtonTapped() {
        
    }
    
    func listButtonTapped() {
        self.mdTextViewWrapper.changeCurrentLine2List()
    }
    
    func orderListButtonTapped() {
        self.mdTextViewWrapper.changeCurrentLine2OrderList()
    }
    
    func keyboardButtonTapped() {
//        self.dismiss(animated: true, completion: nil)
        self.saveButtonTapped?()
    }
}
