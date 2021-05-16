//
//  MDHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

class MDTextViewWrapper:NSObject {
    private weak var textView:UITextView?
    var highlight = MDSyntaxHighlighter(isEdit: true)
    
    init(textView:UITextView) {
        super.init()
        textView.isSelectable = true
        self.textView = textView
        self.textView?.delegate = self
    }
}

extension MDTextViewWrapper: UITextViewDelegate {
    
//    func textViewDidBeginEditing(_ textView: UITextView) {
//        UIApplication.shared.isIdleTimerDisabled = true
//    }
//
//    func textViewDidEndEditing(_ textView: UITextView) {
//        UIApplication.shared.isIdleTimerDisabled = false
//    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let begin = max(range.location - 100, 0)
            let len = range.location - begin
            let nsString = textView.text! as NSString
            let nearText = nsString.substring(with: NSRange(location:begin, length: len))
            let texts = nearText.components(separatedBy: "\n")
            
            let lastLineCount = texts.last!.utf16.count
            let beginning = textView.beginningOfDocument
            guard let from = textView.position(from: beginning, offset: range.location - lastLineCount),
                let to = textView.position(from: beginning, offset: range.location),
                let textRange = textView.textRange(from: from, to: to) else {
                return true
            }
            let newText  =  newLine(texts.last!)
            textView.replace(textRange, withText: newText)
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(highlight), userInfo: nil, repeats: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
           
           }
        self.processHighlight()
    }
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
               return false
    }
}


extension MDTextViewWrapper {
    @objc func processHighlight() {
        guard let textView = self.textView else { return }
        highlight.highlight(textView.textStorage)
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



extension MDTextViewWrapper {
//    func highlightSynax(_ text: NSTextStorage, visibleRange: NSRange? = nil) {
//        let len = (text.string as NSString).length
//        var validRange:NSRange
//        if  let  visibleRange = visibleRange {
//            validRange = visibleRange
//        }else {
//            validRange  = NSRange(location:0, length: len)
//        }
//        
//        text.setAttributes(getTextStyleAttributes(), range: validRange)
//        
//        syntaxArray.forEach { (syntax) in
//            syntax.expression.enumerateMatches(in: text.string, options: .reportCompletion, range: validRange, using: { (match, _, _) in
//                if let range = match?.range {
//                    text.addAttributes(syntax.style.attrs, range: range)
//                }
//            })
//        }
//    }
//    
//    
//    func getTextStyleAttributes() -> [NSAttributedString.Key : Any] {
//        return [.font : UIFont.systemFont(ofSize: 16),
//                .paragraphStyle : paragraphStyle,
//                .foregroundColor : UIColor.primaryText]
//    }
}
