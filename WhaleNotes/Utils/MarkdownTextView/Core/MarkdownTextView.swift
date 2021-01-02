//
//  MarkdownTextView.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/29/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

protocol MarkdownTextViewDelegate {
    func textViewDidChange(_ textView: MarkdownTextView)
    
    func textViewDidEndEditing(_ textView: MarkdownTextView)
}

/**
*  Text view with support for highlighting Markdown syntax.
*/
public class MarkdownTextView: UITextView {
    
    var editorDelegate:MarkdownTextViewDelegate?
    
    let mdTextStorage = MarkdownTextStorage()
    
    public init(frame: CGRect = .zero) {
        
        
        let containerSize = CGSize(width: windowWidth, height: CGFloat.greatestFiniteMagnitude)
        
        let textContainer = NSTextContainer(size: containerSize)
        textContainer.widthTracksTextView = true
        textContainer.lineBreakMode =  .byWordWrapping
        
        let layoutManager = MyLayoutManger()
        layoutManager.addTextContainer(textContainer)
        
        mdTextStorage.addLayoutManager(layoutManager)
        
        super.init(frame: frame, textContainer: textContainer)
        
        mdTextStorage.textView = self
        self.typingAttributes = MarkdownAttributes.mdDefaultAttributes
        
        layoutManager.delegate = self
        
        self.delegate = self
        
//        self.backgroundColor = .red
        
        let keyboardView = MDKeyboardView()
        keyboardView.delegate = self
        
        self.inputAccessoryView = keyboardView
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


extension MarkdownTextView {
    func handleList(line:String,range:NSRange)  {
        let text = line.substring(with: range)
        if let first = text.first,first.isNumber{ // number list
            
        }else {
            self.handleBulletList(range:range,line:line)
        }
    }
    
    func handleBulletList(range:NSRange,line:String)  {
        let sysbolRange = range.lowerBound..<(range.lowerBound+1)
        let bulletSymbol =  line.substring(with:sysbolRange)
        var leadingText = ""
        if range.lowerBound > 0{
            leadingText = line.substring(to: range.lowerBound)
        }
        var str =  ""
        //只有符号
        if sysbolRange.upperBound + 1 == range.upperBound  {
            let start = self.selectedRange.location - 2
            self.textStorage.replaceCharacters(in: NSMakeRange(start, 2), with: "")
        }else {
            str = "\n\(leadingText)\(bulletSymbol) "
            self.insertText(str)
        }
    }
}

extension MarkdownTextView:UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let lineRange  = TextUtils.getLineRange(textView.text, location: range.location)
            let lineText = textView.text.substring(with: lineRange)
            if let range = mdTextStorage.bulletHightlighter.match(line: lineText) {
                self.handleList(line: lineText,range: range)
                return false
            }
        }
        return true
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.typingAttributes = MarkdownAttributes.mdDefaultAttributes
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        editorDelegate?.textViewDidChange(self)
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        editorDelegate?.textViewDidEndEditing(self)
    }
}



extension MarkdownTextView:MDKeyboarActionDelegate {
    func listButtonTapped() {
        self.changeCurrentLine2List()
    }
    
    func orderListButtonTapped() {
        self.changeCurrentLine2OrderList()
    }
    
    func keyboardButtonTapped() {
        self.resignFirstResponder()
    }
    
    
    func changeCurrentLine2List() {
        
        let lineRange  = TextUtils.getLineRange(self.text, location: self.selectedRange.location)
        let lineText = text.substring(with: lineRange)
        if let range = mdTextStorage.bulletHightlighter.match(line: lineText) {
            // 移除 symbol
            let start = lineRange.lowerBound + range.location
            self.textStorage.replaceCharacters(in: NSMakeRange(start, 2), with: "")
            self.selectedRange = NSMakeRange(self.selectedRange.location-2, 0)
        } else{
            // 添加
            let start = lineRange.lowerBound
            self.textStorage.replaceCharacters(in: NSMakeRange(start, 0), with: "- ")
            self.selectedRange = NSMakeRange(self.selectedRange.location+2, 0)
            
        }
    }
    
    
    
}

extension MarkdownTextView {
    
    func changeCurrentLine2OrderList() {
//        let locaction = self.selectedRange.location
//        let lineRange = TextUtils.getLineRange(self.text, location: locaction)
//        let lineText = self.text.substring(with: lineRange)
//
//        if let symbolRange = self.mdTextStorage.orderListHighlighter.getSymbolNSRange(text: lineText) {//移除num
////            let move = lineText.count - 3
//
//            let move = locaction - lineRange.lowerBound - 3
//
//            let sympolL = lineRange.lowerBound + symbolRange.location
//            self.mdTextStorage.replaceCharactersInRange(NSMakeRange(sympolL, 3), withString: "", selectedRangeLocationMove: move)
//
//            //更新其它行
//            self.mdTextStorage.orderListHighlighter.tryUpdateOtherOrderList(textStorage: self.mdTextStorage, cursorPos: locaction-move, numBegin: 1)
//
//            return
//        }
//
//        self.updateLine2NumListItem(location: locaction)

    }
    
    func updateLine2NumListItem(location:Int) {
//        let lineRange = TextUtils.getLineRange(self.text, location: location)
//        let lineText = self.text.substring(with: lineRange)
//
//        var num = 1
//
//        // 获取上一行的symbol num
//        if lineRange.lowerBound  > 0 {
//            let lastLineRange = TextUtils.getLineRange(self.text, location: lineRange.lowerBound-1)
//            let lastLineText = self.text.substring(with: lastLineRange)
//
//            if let lastSymbolRange = self.mdTextStorage.orderListHighlighter.getSymbolNSRange(text: lastLineText)  {
//                let sympolL = lastSymbolRange.location
//                let numStr = NSString(string: lastLineText.substring(with: (sympolL..<1)))
//    //            if numStr != nil {
//    //
//    //            }
//                num = numStr.integerValue + 1
//            }
//        }
//
//        let symbolS = "\(num). "
//        let move = location - lineRange.lowerBound + symbolS.count
//        let sympolL = lineRange.lowerBound
//        self.mdTextStorage.replaceCharactersInRange(NSMakeRange(sympolL, 0), withString: symbolS, selectedRangeLocationMove: move)
//
//
//        self.mdTextStorage.orderListHighlighter.tryUpdateOtherOrderList(textStorage: self.mdTextStorage, cursorPos: location+symbolS.count, numBegin: num+1)
        
    }
}

extension MarkdownTextView:NSLayoutManagerDelegate {
//    public func layoutManager(_ layoutManager: NSLayoutManager, shouldSetLineFragmentRect lineFragmentRect: UnsafeMutablePointer<CGRect>, lineFragmentUsedRect: UnsafeMutablePointer<CGRect>, baselineOffset: UnsafeMutablePointer<CGFloat>, in textContainer: NSTextContainer, forGlyphRange glyphRange: NSRange) -> Bool {
//        
////        var baseline: CGFloat = (lineFragmentRect.pointee.height - biggestLineHeight) / 2
////        baseline += biggestLineHeight
////        baseline -= biggestDescender
////        baseline = min(max(baseline, 0), lineFragmentRect.pointee.height)
//        
//        
//        let a =  ((lineHeightMultiple - 1）* defaultFont.lineheight - defaultFont.descender）/（3 - lineHe）
//
//
//        baselineOffset.pointee = floor(baseline)
//
//        return false
//        
//    }
}
