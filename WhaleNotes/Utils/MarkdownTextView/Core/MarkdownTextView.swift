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



//MARK:  UITextViewDelegate
extension MarkdownTextView:UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let lineRange  = getSelectedLineRange()
            let line = (textView.text as NSString).substring(with: lineRange)
           
            // 匹配
            if let numSymbolRange = mdTextStorage.numListHightlighter.matchSymbol(text: textView.text, lineRange: lineRange){
                let leadingText =  getLineLeadingText(line: line)
                self.handleNumberList(lineRange: lineRange, symbolRange: numSymbolRange,leadingText:leadingText)
                return false
            }
            
            if let bulletSymbolRange = mdTextStorage.bulletHightlighter.matchSymbol(text: textView.text, lineRange: lineRange){
                let leadingText =  getLineLeadingText(line: line)
                self.handleBulletList(lineRange: lineRange, symbolRange: bulletSymbolRange,leadingText:leadingText)
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

//MARK: 处理回车键
extension MarkdownTextView {
    
    func isOnlySymbol(lineRange:NSRange,symbolRange:NSRange,leadingText:String) -> Bool {
        let line = self.text.substring(with: lineRange)
        let enterKeyCount   =   line.last  ==   ENTER_KEY ? 1 : 0
        return (lineRange.length - leadingText.count - enterKeyCount) ==  symbolRange.length
    }
    
    func handleBulletList(lineRange:NSRange,symbolRange:NSRange,leadingText:String)  {
        let isOnlySymbol = self.isOnlySymbol(lineRange: lineRange, symbolRange: symbolRange,leadingText:leadingText)
        if isOnlySymbol {
           replaceAndMoveSelected(range: NSMakeRange(lineRange.location+leadingText.count, symbolRange.length), replace: "")
           return
        }
        let symbol = self.text.substring(with: symbolRange.location..<(symbolRange.location + symbolRange.length))
        let symbolStr = "\n\(leadingText+symbol)"
        self.insertText(symbolStr)
    }
    
    func handleNumberList(lineRange:NSRange,symbolRange:NSRange,leadingText:String)  {
        var num =  0
        var loc =  0
        let isOnlySymbol = self.isOnlySymbol(lineRange: lineRange, symbolRange: symbolRange,leadingText:leadingText)
        if isOnlySymbol {//删除
            replaceAndMoveSelected(range: NSMakeRange(lineRange.location+leadingText.count, symbolRange.length), replace: "")
            
            loc = lineRange.upperBound - symbolRange.length
        }else {
            num = self.text.substring(with: symbolRange.location..<(symbolRange.location + symbolRange.length - 1)).toInt() ?? 0
            num += 1
            let symbolStr = "\n\(leadingText)\(num). "
            self.insertText(symbolStr)
            loc = getSelectedLineRange().upperBound
        }
        
        self.tryUpdateBelowLinesNum(newBeginNum: num+1, loc: loc, lineLeadingText: leadingText)
    }
    
    func getLineLeadingText(line:String) -> String {
        var leadingLength = 0
        if let r =  line.leadingWhiteSpaceAndTabRange() {
            leadingLength = r.length
        }
        let leadingText = line.substring(to: leadingLength)
        return  leadingText
    }
    
    func replaceAndMoveSelected(range:NSRange,replace:String) {

        let move = range.length - replace.length

        let newSelected = self.selectedRange.location-move
        self.textStorage.replaceCharacters(in: range, with: replace)
        self.selectedRange = NSMakeRange(newSelected, 0)
    }
}


//MARK: 键盘 
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
        let lineRange  = (text as NSString).lineRange(for: self.selectedRange)
        
        let line = getSelectedLine()
        
        if let bulletSymbolRange = mdTextStorage.bulletHightlighter.matchSymbol(text: self.text, lineRange: lineRange){
            // 移除 symbol
            replaceAndMoveSelected(range: NSMakeRange(bulletSymbolRange.location, bulletSymbolRange.length), replace: "")
            
        } else{
            
            let symbolStr = "- "
            let lineLeadingText = getLeadingText(line: line)
            
            if let numSymbolRange = mdTextStorage.numListHightlighter.matchSymbol(text: self.text, lineRange: lineRange)  {// 是
                
                let move = abs(numSymbolRange.length - symbolStr.count)
                
                
                replaceAndMoveSelected(range: NSMakeRange(lineRange.location, numSymbolRange.length), replace: symbolStr)
                
                
                self.tryUpdateBelowLinesNum(newBeginNum: 1, loc: lineRange.upperBound - move, lineLeadingText: lineLeadingText)
                
                return
            }
            
            replaceAndMoveSelected(range: NSMakeRange(lineRange.lowerBound, 0), replace: symbolStr)
        }
    }
    
    
    
}

//MARK: number list
extension MarkdownTextView {
    
    func changeCurrentLine2OrderList() {
        let lineRange  = getSelectedLineRange()
        let line = getSelectedLine()
        
        let leadingText = getLeadingText(line: line)
        
        if let symbolRange = mdTextStorage.numListHightlighter.matchSymbol(text: self.text, lineRange: lineRange)  {
            //当前行是索引,移除 num
            let length = symbolRange.length
            
            replaceAndMoveSelected(range: NSMakeRange(symbolRange.location, length), replace: "")
            
            self.tryUpdateBelowLinesNum(newBeginNum: 1, loc: lineRange.upperBound-length, lineLeadingText: leadingText)
            return
        }
        
        var num  = 0
        if let preLineNumAndPending = getRightPreLineNumAndPending(lineRange: lineRange, lineLeadingText: leadingText) {
            num = preLineNumAndPending.0+1
        }else {
            num = 1
        }
        let symbolStr  = "\(num). "
        
        var start = 0
        var count = 0
        
        if let bulletSymbolRange = mdTextStorage.bulletHightlighter.matchSymbol(text: self.text, lineRange: lineRange) {
            start = bulletSymbolRange.location
            count = bulletSymbolRange.length
        }else {
            start = lineRange.lowerBound + leadingText.count
            count = 0
        }
        
        let changedCount = symbolStr.count - count
        
        replaceAndMoveSelected(range: NSMakeRange(start, count), replace: symbolStr)
        
        self.tryUpdateBelowLinesNum(newBeginNum: num+1, loc: lineRange.upperBound+changedCount, lineLeadingText: leadingText)
    }
    
    func getRightPreLineNumAndPending(lineRange:NSRange,lineLeadingText: String) -> (Int,String)?  {
        if lineRange.location == 0 { return nil }
        let preText = self.text.substring(to: lineRange.location-1) // -1 是过滤掉回车
        let lines = Array(preText.components(separatedBy: ENTER_KEY.toString).reversed())
        for line in lines {
            guard let symbolRange = mdTextStorage.numListHightlighter.matchSymbol(text: line, lineRange: NSMakeRange(0, line.count)) else {
                break
            }
            let leadingText = line.substring(with: 0..<(symbolRange.location))
            if leadingText !=  lineLeadingText { continue }
            let index = symbolRange.upperBound - 1
            let num = (line.substring(with: symbolRange.location..<index) as NSString).integerValue
            return (num,leadingText)
        }
        return nil
    }
    
    func getLeadingText(line: String)-> String {
        
        var leadingLength = 0
        if let r =  line.leadingWhiteSpaceAndTabRange() {
            leadingLength = r.length
        }
        let leadingText = line.substring(to: leadingLength)
        return  leadingText
    }
    
    func getSymbolNum() -> Int {
        guard let preLineRange = getSelectedPreLineRange(),
              let symbolRange = mdTextStorage.numListHightlighter.matchSymbol(text: self.text, lineRange: preLineRange)
              else { return 1}
        let index = symbolRange.upperBound - 1
        let num = (self.text.substring(with: symbolRange.location..<index) as NSString).integerValue
        return num + 1
    }
    
    func tryUpdateBelowLinesNum(newBeginNum:Int,loc:Int,lineLeadingText:String)  {
        let otherText = self.text.substring(from: loc)
        let lines = otherText.components(separatedBy: ENTER_KEY.toString)
        
        var lineNum = newBeginNum
        var newLoc = loc
        
        for line in lines  {
            guard let symbolRange = mdTextStorage.numListHightlighter.matchSymbol(text: line, lineRange: NSMakeRange(0, line.count)) else {
                break
            }
            let leadingText = line.substring(with: 0..<(symbolRange.location))
            if leadingText !=  lineLeadingText {
                newLoc = newLoc + line.count + 1
                continue
            }
            let index = symbolRange.upperBound - 1
            let num = (line.substring(with: symbolRange.location..<index) as NSString).integerValue
            if num == lineNum {
                break
            }
            if lineNum == 10 {
                print("")
            }
            let symbolStr = "\(leadingText)\(lineNum). "
            self.textStorage.replaceCharacters(in: NSMakeRange(newLoc, symbolRange.length), with: symbolStr)
            
            // 更新后新的行
            let newLineCount = line.count - (symbolRange.length - symbolStr.count)
            newLoc = newLoc +  newLineCount  +  1    //+1 是换行符
            lineNum += 1
        }
    }
    
}

extension MarkdownTextView {
    func getSelectedLineRange() -> NSRange {
        return (text as NSString).lineRange(for: self.selectedRange)
    }
    
    
//    func getSelectedRangeWithoutEnter()  -> NSRange {
//        let loc = self.selectedRange.location
//
//        let start = text.substring(to: loc).lastIntIndex(of: ENTER_KEY) + 1
//        let endStr  = text.substring(from: loc)
//
//        var end = endStr.firstIntIndex(of: ENTER_KEY)
//        if end ==  -1 {
//            end = text.utf16Count
//        }else {
//            end = text.utf16Count - endStr.utf16Count +  end
//        }
//
//        return NSMakeRange(start, end-start)
//    }
    
//    class func getLineRange(_ string: String, location: Int) -> NSRange {
////        var end = location
//
//        let start = string.substring(to: location).lastIntIndex(of: "\n") + 1
//
//        let endStr  = string.substring(from: location)
//        var end = endStr.firstIntIndex(of: "\n")
//        if end ==  -1 {
//            end = string.utf16Count
//        }else {
//            end = string.utf16Count - endStr.utf16Count +  end
//        }
////        if end > string.count {
////            end = string.count
////        }
//        return (start..<end)
//    }
    func getSelectedLine() -> String {
        return (text as NSString).substring(with: getSelectedLineRange())
    }
    
    func getSelectedPreLineRange() -> NSRange?  {
        let lineRange = getSelectedLineRange()
        let loc = lineRange.location - 1
        if loc < 0 {
            return nil
        }
        return (text as NSString).lineRange(for: NSMakeRange(loc, 1))
    }
}


extension  String {
    func leadingWhiteSpaceAndTabRange() -> NSRange? {
//        regex.firstMatch(in: testString, options: [], range: range) != nil
        let range = self.range(of: "^[ \t]+")
        return range
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
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
           // location of the tap
           var location = point
           location.x -= self.textContainerInset.left
           location.y -= self.textContainerInset.top
           
           // find the character that's been tapped
           let characterIndex = self.layoutManager.characterIndex(for: location, in: self.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
           if characterIndex < self.textStorage.length {
               // if the character is a link, handle the tap as UITextView normally would
            if (self.textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil) {
                   return nil
               }
           }
           
           // otherwise return nil so the tap goes on to the next receiver
           return self
       }
}
