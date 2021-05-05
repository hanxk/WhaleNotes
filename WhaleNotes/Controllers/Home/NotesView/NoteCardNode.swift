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
    static let padding:CGFloat = 12
    static let spacing:CGFloat = 10
    static let insetH:CGFloat = 12
    static let insetV:CGFloat = 14
    static let cornerRadius:CGFloat = 6
    
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
    
    
    var timer2: Timer? = nil
    private var titleEditNode :ASEditableTextNode?
    
    private var mdTextViewWrapper:MDTextViewWapper?
    private var contentEditNode :ASEditableTextNode?
    
    private var footerProvider:NoteCardProvider!
    
    private var tagsProvider:NoteCardProvider?
    
    private let toolbar = MDToolbar()
    
    private var mdHelper:MDHelper?
    
    var highlightmanager = MarkdownHighlightManager()
    
    let shadowOffsetY:CGFloat = 4
    private lazy var  cardbackground = ASDisplayNode().then {
        $0.backgroundColor = .white
        $0.cornerRadius = StyleConfig.cornerRadius
        
        
        if isEditing  {
//            $0.shadowColor = UIColor(red: 0.969, green: 0.969, blue: 0.969, alpha: 0.7).cgColor
//            $0.shadowOpacity = 1
//            $0.shadowRadius = 4
//            $0.shadowOffset = .zero
            
            //            $0.layer.borderWidth = 1
            //            $0.layer.borderColor = UIColor(red: 0.094, green: 0.075, blue: 0.125, alpha: 0.1).cgColor
        }
        $0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.005).cgColor
        $0.shadowOpacity = 1
        $0.shadowRadius = 1
        $0.shadowOffset = CGSize(width: 0, height: 0)
//        $0.shadowOpacity = 1
//        $0.shadowRadius = 6
//        $0.shadowOffset = .zero
        
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
                $0.isUserInteractionEnabled =  isEditing
                $0.delegate = self
                $0.textView.tag = EditViewTag.title.rawValue
            }
            self.addSubnode(titleNode)
            self.titleEditNode = titleNode
        }
        
        // 内容
        if isEditing || note.content.isNotEmpty {
            
            
            
            
            let content = note.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let containerSize = CGSize.zero
            
            let style = MDStyle(fontSize: 16)
            let textStorage =  MarkdownTextStorage(style: style)
            let layoutManager = MyLayoutManger()
            
            let textKitComponents: ASTextKitComponents =
                .init(textStorage: textStorage,
                      textContainerSize: containerSize,
                      layoutManager: layoutManager)
            
            let placeholderTextKit: ASTextKitComponents =
                .init(attributedSeedString:  getContentPlaceholderAttributes(attrs: style.mdDefaultAttributes),
                      textContainerSize: containerSize)
            
            
            let contentNode = ASEditableTextNode.init(textKitComponents: textKitComponents,
                                                      placeholderTextKitComponents: placeholderTextKit).then {
                                                        $0.placeholderEnabled  = isEditing
                                                        //                                $0.attributedPlaceholderText = getContentPlaceholderAttributes()
                                                        $0.attributedText =  NSMutableAttributedString(string: content, attributes: style.mdDefaultAttributes)
                                                        $0.scrollEnabled = false
                                                        //                $0.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
                                                        $0.textView.isEditable = isEditing
                                                        $0.typingAttributes = Dictionary(uniqueKeysWithValues:
                                                                                            style.mdDefaultAttributes.map { key, value in (key.rawValue, value) })
                                                        $0.delegate = self
                                                        $0.isUserInteractionEnabled =  isEditing
                                                        $0.textView.tag = EditViewTag.content.rawValue
                                                        $0.tintColor =  UIColor.link
                                                        //                                                $0.backgroundColor = .red
                                                      }
            self.addSubnode(contentNode)
            self.contentEditNode = contentNode
            
            
            let mdTextViewWrapper = MDTextViewWapper(textView: contentNode.textView)
            mdTextViewWrapper.textviewTappedDelegate =  self
            self.mdTextViewWrapper = mdTextViewWrapper
            
            
            if isNew { // 新建
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // your code here
                    contentNode.becomeFirstResponder()
                }
            }
        }
        
        self.cardActionEmit  = action
        
        // 标签
        //        if noteInfo.tags.count > 0 {
        //            let tagsProvider = NoteTagsProvider(noteInfo: noteInfo, tagsSize: tagTitlesWidth)
        //            self.tagsProvider = tagsProvider
        //            tagsProvider.attach(cell: self)
        //        }
        
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
            $0.spacing = 4
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

extension NoteCardNode:MDTextViewTappedDelegate {
    func textViewTagTapped(_ textView: UITextView, tag: String) {
        
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        guard let contentNode = self.contentEditNode else {
            return super.hitTest(point, with: event)
        }
        if let view = mdTextViewWrapper?.hitTest(self.convert(point, to: contentNode), with: event)
        {
            return view
        }
        return super.hitTest(point, with: event)
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

//MARK: ASEditableTextNodeDelegate
extension NoteCardNode: ASEditableTextNodeDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        
        // your action here
        
        return true
    }
    
    
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let textView = editableTextNode.textView
        let newText = textView.text ??  ""
        
        //        mdHelper?.textViewDidChange(editableTextNode.textView)
        //        if  editableTextNode.textView.tag == 1 {
        //            titleEditNode?.attributedText = getTitleAttributes(text: text)
        //        }else {
        //            contentEditNode?.attributedText = getContentAttributes(text: text)
        //        }
        if  editableTextNode.textView.tag == EditViewTag.title.rawValue {
            note.title  = newText
            return
        }
        
        //  找到最后一行尝试去 highlight
        
        //1. 先找到光标所在行
        if let selectedRange = textView.selectedTextRange {
            let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
            print("\(cursorPosition)")
        }
        
        guard let textRange = textView.getCursorTextRange()
        else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: textRange.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: textRange.end)
        
        let range = NSRange(location: start, length: end-start)
        //        let oldLength = note.content.length
        //
        //        var start  =  oldLength > 0 ? oldLength : oldLength
        //
        //        let newLength = newText.length
        //        var len  = abs(oldLength - newLength)
        //        if len == 0  {
        //            start  -= 1
        //            len = 1
        //            print(newText)
        //        }
        //        let visibleRange =  NSMakeRange(start, len)
        //        note.content  = newText
        //        highlightmanager.highlight(editableTextNode.textView.textStorage,visibleRange: visibleRange)
        
        timer2?.invalidate()
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(highlight(sender:)), userInfo: range, repeats: false)
        //        _textWidth = 0
    }
    
    func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        guard let tag = EditViewTag(rawValue: editableTextNode.textView.tag)  else  { return }
        self.textEdited?(text,tag)
    }
    
    
    
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //       return self.mdHelper?.textView(editableTextNode.textView, shouldChangeTextIn: range, replacementText: text) ?? false
        let textView = editableTextNode.textView
        if text == "\n" {
            let begin = max(range.location - 100, 0)
            let len = range.location - begin
            let nsString = textView.text! as NSString
            let nearText = nsString.substring(with: NSRange(location:begin, length: len))
            let texts = nearText.components(separatedBy: "\n")
            //            if texts.count < 2 {
            //                return true
            //            }
            
            //            let lastLineCount = texts.last!.count   // emoji bug
            //            let lastLineCount = texts.last!.utf16.count
            //            let beginning = textView.beginningOfDocument
            //            guard let from = textView.position(from: beginning, offset: range.location - lastLineCount),
            //                let to = textView.position(from: beginning, offset: range.location),
            //                let textRange = textView.textRange(from: from, to: to) else {
            //                return true
            //            }
            let newText  =  newLine2(texts.last!)
            if  newText == "\n" {
                return  true
            }
            //            textView.replace(textRange, withText: newText)
            let from = textView.text.count
            textView.insertText(newText)
            let to = textView.text.count
            
            //            let textRange = textView.textRange(from: from, to: to)
            
            return false
        }
        return true
    }
    
    @objc func highlight(sender: Timer) {
        let range = sender.userInfo as! NSRange
        highlightmanager.highlight(contentEditNode!.textView.textStorage,visibleRange: range)
        self.textChanged?(self.contentEditNode!.textView.text)
    }
    
    func newLine2(_ last: String) -> String {
        if last.hasPrefix("- [x] ") {
            return "\n- [x] "
        }
        if last.hasPrefix("- [ ] ") {
            return "\n- [ ] "
        }
        if let str = last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) ") {
            if last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) +[\\S]+") == nil {
                return "\n"
            }
            guard let range = str.firstMatchRange("[0-9]+") else { return "\n" + str }
            let num = str.substring(with: range).toInt() ?? 0
            return "\n" + str.replacingCharacters(in: range, with: "\(num+1)")
        }
        if let str = last.firstMatch("^( {4}|\\t)+") {
            return "\n" + str
        }
        return "\n"
    }
    
    
    func newLine(_ last: String) -> String {
        if last.hasPrefix("- [x] ") {
            return last + "\n- [x] "
        }
        if last.hasPrefix("- [ ] ") {
            return last + "\n- [ ] "
        }
        if let str = last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) ") {
            if last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) +[\\S]+") == nil {
                return "\n"
            }
            guard let range = str.firstMatchRange("[0-9]+") else { return last + "\n" + str }
            let num = str.substring(with: range).toInt() ?? 0
            return last + "\n" + str.replacingCharacters(in: range, with: "\(num+1)")
        }
        if let str = last.firstMatch("^( {4}|\\t)+") {
            return last + "\n" + str
        }
        return last + "\n"
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
        self.contentEditNode?.textView.inputAccessoryView = toolbar
    }
}
