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

protocol NoteCardNodeDelegate {
    func tagTapped(tag:Tag)
}




enum StyleConfig {
    static let padding:CGFloat = 12
    static let spacing:CGFloat = 14
    static let insetH:CGFloat = 12
    static let insetV:CGFloat = 14
    static let cornerRadius:CGFloat = 8
    
    static let footerHeight:CGFloat = 46
    
    static let iconTintColor  = UIColor(hexString: "#777777")
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
    
    var delegate:NoteCardNodeDelegate? = nil
    
    private var textChanged: ((String) -> Void)?
    private var cardActionEmit: ((NoteCardAction) -> Void)?
    private var textEdited: ((String,EditViewTag) -> Void)?
    
    
    var timer2: Timer? = nil
    private var titleEditNode :ASEditableTextNode?
    
    private var mdTextViewWrapper:MDTextViewWapper?
    private var contentNode :ASTextNode!
    
    private var footerProvider:NoteCardProvider!
    
    private var tagsProvider:NoteCardProvider?
    
    private let toolbar = MDToolbar()
    
    private var mdHelper:MDHelper?
    
    var highlightmanager = MDSyntaxHighlighter()
    
    let shadowOffsetY:CGFloat = 4
    private lazy var  cardbackground = ASDisplayNode().then {
        $0.backgroundColor = .white
        
        $0.cornerRadius = StyleConfig.cornerRadius
        $0.borderWidth = 1
        $0.borderColor = UIColor(red: 0.937, green: 0.945, blue: 0.957, alpha: 1).cgColor
        
        $0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
        $0.shadowOpacity = 1
        $0.shadowRadius = 5
        $0.shadowOffset = CGSize(width: 0, height: 2)
    }
    
    
    init(noteInfo:NoteInfo,attString:NSAttributedString,action: @escaping (NoteCardAction) -> Void) {
        super.init()
        self.noteInfo = noteInfo
        self.addSubnode(cardbackground)
        self.isUserInteractionEnabled = true
        
        let contentNode = ASTextNode()
        contentNode.attributedText = attString
        contentNode.delegate = self
        contentNode.isSelected = true
        contentNode.attributedText = attString
        self.contentNode = contentNode
        self.addSubnode(contentNode)
        
        self.cardActionEmit  = action
        
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
        
        contentNode.linkAttributeNames = [NSAttributedString.Key.tag.rawValue,NSAttributedString.Key.link.rawValue]
        contentNode.isUserInteractionEnabled = true
    }
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let vinsets = UIEdgeInsets(top:StyleConfig.insetV, left: StyleConfig.insetH, bottom: 0, right: StyleConfig.insetH)
        
        let vContentLayout = ASStackLayoutSpec.vertical().then {
            $0.style.flexGrow = 1.0
            $0.style.flexShrink = 1.0
            $0.spacing = 4
        }
//        if let titleEditNode = self.titleEditNode {
//            vContentLayout.children?.append(titleEditNode)
//        }
//        if let contentEditNode = self.contentEditNode {
//            vContentLayout.children?.append(contentEditNode)
//        }
        vContentLayout.children?.append(contentNode)
        
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
        let font =  MDStyle.generateDefaultFont(fontSize: 18,weight: .medium)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1
        paragraphStyle.lineBreakMode = .byWordWrapping;
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor:UIColor.cardText
        ]
        return attributes
    }
    
    
    func getContentAttributesString(attrs:[NSAttributedString.Key: Any]) -> [String: Any] {
        
        return Dictionary(uniqueKeysWithValues:
                            attrs.map { key, value in (key.rawValue, value) })
    }
    
    
    func getContentPlaceholderAttributes(attrs:[NSAttributedString.Key: Any]) -> NSAttributedString {
        var contentAttr = attrs
        contentAttr[.foregroundColor] = UIColor.lightGray
        return NSMutableAttributedString(string: "写点什么", attributes: contentAttr)
    }
}


extension NoteCardNode: ASTextNodeDelegate {
    
    func textNode(_ textNode: ASTextNode!, tappedLinkAttribute attribute: String!, value: Any!, at point: CGPoint, textRange: NSRange) {
        
        if attribute == NSAttributedString.Key.tag.rawValue {// tag
            
            
            if let tagTitle = value as? String {
                let tagTitles = tagTitle.split("#")
                if tagTitles.count == 0 { return }
                let tagValue = tagTitles[tagTitles.count-1]
                if let tag = self.noteInfo.tags.first(where: {$0.title == tagValue}) {
                    delegate?.tagTapped(tag: tag)
                }
            }
            return
        }
        if let  url =  value as? URL {
            UIApplication.shared.open(url)
        }
    }
    
    func textNode(_ textNode: ASTextNode!, shouldHighlightLinkAttribute attribute: String!, value: Any!, at point: CGPoint) -> Bool {
        return true
    }
}


extension NoteCardNode {
    fileprivate func updateNote() {
        
    }
}

extension NoteCardNode {
    func setupToolbar() {
        toolbar.frame =  CGRect(x: 0, y: 0, width: self.frame.width, height: 40)
        //        toolbar.actionButtonTapped = {
        //            self.handleActionType(actionType: $0)
        //        }
        //        editView.inputAccessoryView = toolbar
//        self.contentEditNode?.textView.inputAccessoryView = toolbar
    }
}
