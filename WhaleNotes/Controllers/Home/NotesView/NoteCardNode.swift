//
//  NoteCardCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import AsyncDisplayKit


protocol NoteCardProvider {
    func attach(cell:ASCellNode)
    func layout(constrainedSize: ASSizeRange) -> ASLayoutSpec
}

enum StyleConfig {
    static let padding:CGFloat = 10
    static let spacing:CGFloat = 12
    static let insetH:CGFloat = 12
    static let insetV:CGFloat = 12
    static let cornerRadius:CGFloat = 8
    
    static let footerHeight:CGFloat = 48
    
    static let iconTintColor  = UIColor(hexString: "#A4A4A4")
}

enum NoteCardAction: Int {
    case edit = 1
    case tag = 2
    case photo = 3
    case save = 4
    case menu = 5
}

enum NoteCardMode: Int {
    case normal = 0
    case editing = 1
    case new = 2
}


enum EditViewTag: Int {
    case title = 1
    case content = 2
}

class NoteCardNode: ASCellNode {
    
    private var noteInfo:NoteInfo!
    private var note:Note {
        get {
            return noteInfo.note
        }
        set {
            noteInfo.note = newValue
        }
    }
    private var tagTitlesWidth:[CGFloat] = []
    
    var isEditing = false
    var mode:NoteCardMode = .normal
    
    var isNew:Bool {
        return note.createdAt == note.updatedAt
    }
    
    private var textChanged: ((String) -> Void)?
    private var cardActionEmit: ((NoteCardAction) -> Void)?
    private var textEdited: ((String,EditViewTag) -> Void)?
    
    
    private var titleEditNode :ASEditableTextNode?
    private var contentEditNode :ASEditableTextNode?
    
    private var footerProvider:NoteCardProvider!
    
    private var tagsProvider:NoteCardProvider?
    
    
    
    let shadowOffsetY:CGFloat = 4
    private lazy var  cardbackground = ASDisplayNode().then {
        $0.backgroundColor = .white
        $0.cornerRadius = StyleConfig.cornerRadius
        
        
        if isEditing  {
            $0.shadowColor = UIColor(red: 0.169, green: 0.161, blue: 0.18, alpha: 0.09).cgColor
            $0.shadowOpacity = 1
            $0.shadowRadius = 8
            $0.shadowOffset = CGSize(width: 2, height: 2)
            
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor(red: 0.094, green: 0.075, blue: 0.125, alpha: 0.1).cgColor
        }
        
        //        $0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.03).cgColor
        //        $0.shadowRadius = 5
        //        $0.shadowOffset = CGSize(width: 0, height: 0)
        //        $0.shadowOpacity = 1
    }
    
    
    init(noteInfo:NoteInfo,tagTitlesWidth:[CGFloat],isEditing:Bool = false,action: @escaping (NoteCardAction) -> Void) {
        super.init()
        self.isEditing = isEditing
        self.noteInfo = noteInfo
        self.tagTitlesWidth = tagTitlesWidth
        self.addSubnode(cardbackground)
        
        // 标题
        if isEditing || note.title.isNotEmpty {
            let titleNode = ASEditableTextNode().then {
                $0.placeholderEnabled  = isEditing
                $0.attributedText = NSMutableAttributedString(string: note.title, attributes: getTitleAttributes())
                $0.attributedPlaceholderText = getTitlePlaceHolderAttributesString()
                $0.scrollEnabled = false
                $0.typingAttributes = getTitleAttributesString()
                $0.textView.isEditable = isEditing
                $0.delegate = self
                $0.textView.tag = EditViewTag.title.rawValue
            }
            self.addSubnode(titleNode)
            self.titleEditNode = titleNode
        }
        
        // 内容
        if isEditing || note.content.isNotEmpty {
            let contentNode = ASEditableTextNode().then {
                $0.placeholderEnabled  = isEditing
                $0.attributedPlaceholderText = getContentPlaceholderAttributes()
                $0.attributedText =  NSMutableAttributedString(string: note.content, attributes: getContentAttributes())
                $0.scrollEnabled = false
                $0.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
                $0.textView.isEditable = isEditing
                $0.typingAttributes = getContentAttributesString()
                $0.delegate = self
                $0.textView.tag = EditViewTag.content.rawValue
            }
            self.addSubnode(contentNode)
            self.contentEditNode = contentNode
            
            if isNew { // 新建
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // your code here
                    contentNode.becomeFirstResponder()
                }
            }
        }
        
        self.cardActionEmit  = action
        
        // 标签
        if noteInfo.tags.count > 0 {
            let tagsProvider = NoteTagsProvider(noteInfo: noteInfo, tagsSize: tagTitlesWidth)
            self.tagsProvider = tagsProvider
            tagsProvider.attach(cell: self)
        }
        
        // footer
        if isEditing {
            let provider  = ToolbarEditingProvider()
            provider.cardActionEmit = self.cardActionEmit
            self.footerProvider = provider
        }else  {
            let provider  = ToolbarProvider(noteInfo: self.noteInfo)
            provider.cardActionEmit = self.cardActionEmit
            self.footerProvider = provider
        }
        self.footerProvider.attach(cell: self)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
    }
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let vinsets = UIEdgeInsets(top:StyleConfig.insetV, left: StyleConfig.insetH, bottom: 0, right: StyleConfig.insetH)
        
        let vContentLayout = ASStackLayoutSpec.vertical().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.spacing = 8
        }
        if let titleEditNode = self.titleEditNode {
            vContentLayout.children?.append(titleEditNode)
        }
        if let contentEditNode = self.contentEditNode {
            vContentLayout.children?.append(contentEditNode)
        }
        
        // tags
        if let tagsProvider = self.tagsProvider {
            let maxWidth = constrainedSize.max.width - StyleConfig.insetH*2 - StyleConfig.padding*2
            let cs = ASSizeRange(min: .zero, max: CGSize(width: maxWidth, height: 100))
            let tagsLayout = tagsProvider.layout(constrainedSize: cs)
            vContentLayout.children?.append(tagsLayout)
        }
        
        let vRootLayout = ASStackLayoutSpec.vertical().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.spacing = 0
        }
        
        // footer
        let footerLayout = self.footerProvider.layout(constrainedSize: constrainedSize)
        vRootLayout.children = [vContentLayout,footerLayout]
        
        
        let vLayoutInsetSpec = ASInsetLayoutSpec(insets: vinsets, child: vRootLayout)
        
        
        let bgLayoutSpec:ASLayoutSpec =  ASBackgroundLayoutSpec(child: vLayoutInsetSpec, background: cardbackground).then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
        }
        let insets = UIEdgeInsets(top:StyleConfig.spacing/2, left: StyleConfig.padding, bottom: StyleConfig.spacing/2, right: StyleConfig.padding)
        return  ASInsetLayoutSpec(insets: insets, child: bgLayoutSpec)
    }
    
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
    
    func cardActionEmit(action: @escaping (NoteCardAction) -> Void) {
        self.cardActionEmit = action
    }
    func textEdited(action: @escaping (String,EditViewTag) -> Void) {
        self.textEdited = action
    }
}

extension NoteCardNode {
    
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
        let font =  UIFont.systemFont(ofSize: 18, weight: .medium)
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
    
    func getContentAttributes() -> [NSAttributedString.Key: Any] {
        let font =  UIFont.systemFont(ofSize: 16, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.3
        paragraphStyle.lineBreakMode = .byWordWrapping;
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor:UIColor.cardText,
        ]
        return attributes
    }
    
    func getContentAttributesString() -> [String: Any] {
        
        return Dictionary(uniqueKeysWithValues:
                            getContentAttributes().map { key, value in (key.rawValue, value) })
    }
    
    
    func getContentPlaceholderAttributes() -> NSAttributedString {
        var contentAttr = getContentAttributes()
        contentAttr[.foregroundColor] = UIColor.lightGray
        return NSMutableAttributedString(string: "写点什么", attributes: contentAttr)
    }
}

extension NoteCardNode: ASEditableTextNodeDelegate {
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        self.textChanged?(text)
//        if  editableTextNode.textView.tag == 1 {
//            titleEditNode?.attributedText = getTitleAttributes(text: text)
//        }else {
//            contentEditNode?.attributedText = getContentAttributes(text: text)
//        }
        if  editableTextNode.textView.tag == EditViewTag.title.rawValue {
            note.title  = text
        }else {
            note.content  = text
        }
    }
    
    func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        guard let tag = EditViewTag(rawValue: editableTextNode.textView.tag)  else  { return }
        self.textEdited?(text,tag)
    }
}


extension NoteCardNode {
    fileprivate func updateNote() {
        
    }
}
