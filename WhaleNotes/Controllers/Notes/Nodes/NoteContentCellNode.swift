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
//    lazy var contentNode = ASEditableTextNode().then {
//        $0.textContainerInset = UIEdgeInsets(top: 6, left: MDEditorConfig.paddingH, bottom: 0, right: MDEditorConfig.paddingH)
//        $0.scrollEnabled = false
//        $0.placeholderEnabled = true
//        $0.typingAttributes = getContentAttributesString()
//        $0.attributedPlaceholderText = getContentPlaceHolderAttributesString()
//        $0.delegate = self
//        $0.textView.tag = EditViewTag.content.rawValue
//    }
    
    
    var textViewH:CGFloat = 100
    
    lazy var textView = MarkdownTextView(frame: .zero).then {
        $0.isScrollEnabled = false
        $0.delegate =  self
        $0.backgroundColor  = .red
    }
    
    lazy var textNode = ASDisplayNode { () -> UIView in
        
        return self.textView
    }
    
    
    private(set) var content:String  = ""
    
    //md
    var timer2: Timer? = nil
    var highlightmanager = MarkdownHighlightManager()
    private var textChanged: ((String) -> Void)?
    private var textDidFinishEditing: ((String) -> Void)?
    
    
    private var mdHelper:MDHelper!
    
    
    init(title:String) {
        super.init()
        self.content = title
//        contentNode.attributedText = NSMutableAttributedString(string: title, attributes: getTitleAttributes())
//        self.addSubnode(contentNode)
        
        self.addSubnode(textNode)
        self.backgroundColor =  .blue
//        let mdHelper = MDHelper(editView: contentNode.textView)
//        self.mdHelper = mdHelper
//        mdHelper.loadText(content)
        self.textView.attributedText = NSMutableAttributedString(string: title, attributes: getContentAttributes())
        
//        highlightmanager.highlight(contentNode.textView.textStorage,visibleRange: nil)
        self.textChanged?(title)
        
//        timer2?.invalidate()
//        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(highlight(sender:)), userInfo: nil, repeats: false)
//        highlightmanager.highlight(contentNode.textView.textStorage,visibleRange: nil)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let insets = UIEdgeInsets(top:0, left: 0, bottom: 0, right: 0)
        textNode.style.width = ASDimensionMake(constrainedSize.max.width)
        textNode.style.height = ASDimensionMake(textViewH+10)
//        adjustUITextViewHeight(arg: textView)
        
        return  ASInsetLayoutSpec(insets: insets, child: textNode)
    }
    
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
    func textDidFinishEditing(action: @escaping (String) -> Void) {
        self.textDidFinishEditing = action
    }
    
    func adjustUITextViewHeight(arg : UITextView)
    {
        arg.translatesAutoresizingMaskIntoConstraints = true
        arg.sizeToFit()
    }
}


extension NoteContentCellNode: ASEditableTextNodeDelegate {
    func editableTextNodeDidUpdateText(_ editableTextNode: ASEditableTextNode) {
        let textView = editableTextNode.textView
//        let newText = textView.text ??  ""
        
        
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
        
        timer2?.invalidate()
        timer2 = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(highlight(sender:)), userInfo: range, repeats: false)
    }
    
    func editableTextNodeDidFinishEditing(_ editableTextNode: ASEditableTextNode) {
        let text = editableTextNode.textView.text ??  ""
        self.textDidFinishEditing?(text)
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
        let range = sender.userInfo as? NSRange
//        highlightmanager.highlight(contentNode.textView.textStorage,visibleRange: range)
//        self.textChanged?(self.contentNode.textView.text)
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
        return highlightmanager.getTextStyleAttributes()
    }
}

extension NoteContentCellNode:UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
        let fixedWidth = textView.frame.size.width
//           textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
//           let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
//
//        self.textViewH = newSize.height
//        print(self.textViewH)
        self.textViewH  += 40
        self.textChanged?(textView.text)
    }
}
