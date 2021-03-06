//
//  NoteContentCellNode.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/24.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import AsyncDisplayKit

protocol NoteContentCellNodeDelegate: AnyObject {
    func textChanged(_ cellNode:NoteContentCellNode)
    func editableTextNodeDidBeginEditing(_ cellNode:NoteContentCellNode)
    func saveButtonTapped(_ cellNode:NoteContentCellNode)
    func pickPhotoButtonTapped(sourceType:UIImagePickerController.SourceType)
}

class NoteContentCellNode:ASCellNode {
    
    var textNode:ASEditableTextNode!
    var mdTextViewWrapper:MDTextViewWrapper!
    var textView:UITextView {
        return textNode.textView
    }
    private(set) var content:String  = ""
    var delegate:NoteContentCellNodeDelegate?
    private var mdHelper:MDHelper!
    
//    private lazy var keyboardView = MDKeyboardView().then {
//        $0.delegate = self
//    }
    
    var bar:KeyboardToolBar!
    
    init(title:String) {
        super.init()
        self.content = title
        
        self.textNode =  generateASEditableTextNode(content: title)
        self.bar  = KeyboardToolBar()
        
        bar.delegate = self
        
        self.textView.inputAccessoryView = bar.toolbar
        self.textNode.attributedText = getContentAttributesString(content: content)
        
        self.addSubnode(textNode)
        
        let mdTextViewWrapper = MDTextViewWrapper(textView: textNode.textView)
        self.mdTextViewWrapper = mdTextViewWrapper
        
        self.editableTextNodeDidUpdateText(textNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top:0, left: MDEditorConfig.paddingH, bottom: 0, right: MDEditorConfig.paddingH)
        let spec =  ASInsetLayoutSpec(insets: insets, child: textNode)
        return spec
    }
    
    func generateASEditableTextNode(content:String)  -> ASEditableTextNode {
        
//        let style = MDStyle(fontSize: 16)
        
//        let textStorage =  MarkdownTextStorage(style: style)
//        let layoutManager = MyLayoutManger()
                
//        let textKitComponents: ASTextKitComponents =
//                    .init(textStorage: textStorage,
//                          textContainerSize: .zero,
//                          layoutManager: layoutManager)
//
//        let placeholderTextKit: ASTextKitComponents =
//                    .init(attributedSeedString:  getContentPlaceHolderAttributesString(),
//                          textContainerSize: .zero)
        let contentNode = ASEditableTextNode.init().then {
//        let contentNode = ASEditableTextNode.init(textKitComponents: ASTextKitComponents.init(), placeholderTextKitComponents: placeholderTextKit).then {
                        $0.placeholderEnabled  = false
                        $0.scrollEnabled = false
//                        $0.textView.font = MDEditStyleConfig.normalFont
                        $0.textView.isEditable =   true
                        $0.delegate = self
                        $0.textView.tag = EditViewTag.content.rawValue
                        $0.tintColor =  UIColor.cursor
                        $0.typingAttributes = getContentAttributesString()
         }
        contentNode.style.minHeight = ASDimensionMake(100)
        return  contentNode
    }
}

extension NoteContentCellNode: ASEditableTextNodeDelegate {
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let textView = editableTextNode.textView
        self.mdTextViewWrapper.textViewDidChange(textView)
        delegate?.textChanged(self)
    }
    
    func editableTextNodeShouldBeginEditing(_ editableTextNode: ASEditableTextNode) -> Bool {
        self.delegate?.editableTextNodeDidBeginEditing(self)
        return true
    }
    
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let textView = editableTextNode.textView
        return self.mdTextViewWrapper.textView(textView, shouldChangeTextIn: range, replacementText: text)
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
        return NSMutableAttributedString(string: " ", attributes: titleAttr)
    }
    
    
    func getContentAttributesString(content:String) -> NSAttributedString {
        let titleAttr = getContentAttributes()
        return NSMutableAttributedString(string: content, attributes: titleAttr)
    }

    private func getContentAttributes() -> [NSAttributedString.Key: Any] {
        return  MDSyntaxHighlighter.normalStyle.attrs
    }
}


extension NoteContentCellNode:KeyboardToolBarDelegate {
    func headerButtonTapped() {
        
    }
    
    func pickPhotoButtonTapped(sourceType:UIImagePickerController.SourceType) {
        self.delegate?.pickPhotoButtonTapped(sourceType: sourceType)
    }
    
    func boldButtonTapped() {
        self.mdTextViewWrapper.change2Bold()
    }
    
    func tagButtonTapped() {
        self.mdTextViewWrapper.change2Tag()
    }
    
    func listButtonTapped() {
        self.mdTextViewWrapper.changeCurrentLine2List()
    }
    
    func orderListButtonTapped() {
        self.mdTextViewWrapper.changeCurrentLine2OrderList()
    }
    
    func keyboardButtonTapped() {
        self.delegate?.saveButtonTapped(self)
    }
    
}
