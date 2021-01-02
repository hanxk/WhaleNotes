//
//  MDEditorViewProvider.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/23.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import AsyncDisplayKit

class MDEditorViewProvider: NSObject, NoteCardProvider {
    
    var isEditing:Bool = false
    var textChanged: ((String) -> Void)?
    private var textEdited: ((String) -> Void)?
    
//    private var editorView:ASEditableTextNode!
    private var mdHelper:MDHelper!
    
    private lazy  var  editorView = ASEditableTextNode().then {
        $0.placeholderEnabled  = false
//        $0.attributedPlaceholderText = getContentPlaceholderAttributes()
//            $0.attributedText =  NSMutableAttributedString(string: note.content, attributes: getContentAttributes())
        $0.scrollEnabled = false
        $0.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        $0.textView.isEditable = false
        $0.textView.isSelectable = false
        $0.textView.selectedTextRange = nil
        $0.textView.isUserInteractionEnabled = false
        $0.isUserInteractionEnabled   =  false
//        $0.typingAttributes = getContentAttributesString()
        $0.delegate = self
    }
   
    var text:String = ""
   
    init(isEditing:Bool,text:String) {
        super.init()
        self.isEditing = isEditing
        self.text = text
        self.mdHelper = MDHelper(editView: editorView.textView)
    }
    
    func attach(cell: ASCellNode) {
        editorView.attributedText =  NSMutableAttributedString(string: text, attributes: getContentAttributes())
        mdHelper.loadText(text)
        cell.addSubnode(editorView)
    }
    
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let layout = ASStackLayoutSpec.horizontal().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
        }
        layout.children = [editorView]
        return layout
    }
    
    
    func getContentAttributes() -> [NSAttributedString.Key: Any] {
        let font =  UIFont.systemFont(ofSize: 15, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        paragraphStyle.lineBreakMode = .byWordWrapping;
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor:UIColor.cardText,
        ]
        return attributes
    }
}


extension MDEditorViewProvider: ASEditableTextNodeDelegate {
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        self.textChanged?(text)
        
        mdHelper.textViewDidChange(editableTextNode.textView)
//        if  editableTextNode.textView.tag == 1 {
//            titleEditNode?.attributedText = getTitleAttributes(text: text)
//        }else {
//            contentEditNode?.attributedText = getContentAttributes(text: text)
//        }
//        if  editableTextNode.textView.tag == EditViewTag.title.rawValue {
//            note.title  = text
//        }else {
//            note.content  = text
//        }
    }
    
    func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        self.textEdited?(text)
    }
    
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
       return self.mdHelper.textView(editableTextNode.textView, shouldChangeTextIn: range, replacementText: text)
    }
}
