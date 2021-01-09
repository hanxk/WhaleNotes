//
//  MDTextViewWapper.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/8.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

protocol MDTextViewTappedDelegate {
    func textViewTagTapped(_ textView: UITextView, tag: String)
    func textViewLinkTapped(_ textView: UITextView, link: String)
}

extension MDTextViewTappedDelegate {
    
    func textViewLinkTapped(_ textView: UITextView, link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}

class MDTextViewWapper: NSObject {
    
    var textStorage:MarkdownTextStorage!
    
    var highlightManager:MDHighlightManager {
        return textStorage.highlightManager
    }
    
    weak var textView:UITextView?
    var text:String {
        return textView?.text ?? ""
    }
    private var tempTime:Int64  = 0
    var editorDelegate:MarkdownTextViewDelegate?
    var textviewTappedDelegate:MDTextViewTappedDelegate?
    
    var selectedRange:NSRange {
        get { return self.textView?.selectedRange ?? NSMakeRange(0, 0)
        }
        set {
            self.textView?.selectedRange = newValue
        }
    }
    
    
    init(textView: UITextView,isEditable:Bool  = false) {
        super.init()
        self.textView = textView
        self.textStorage = (textView.textStorage as! MarkdownTextStorage)
        
        if isEditable   {
            let keyboardView = MDKeyboardView()
            keyboardView.delegate = self
            textView.inputAccessoryView = keyboardView
        }
        
        highlightManager.highlight(textStorage: textStorage, range:NSMakeRange(0, textView.text.count))
        
    }
    
    func insertText(_ text:String) {
        self.textView?.insertText(text)
    }
}

extension MDTextViewWapper:MDKeyboarActionDelegate {
    func listButtonTapped() {
        self.changeCurrentLine2List()
    }
    
    func orderListButtonTapped() {
        self.changeCurrentLine2OrderList()
    }
    
    func keyboardButtonTapped() {
        self.textView?.resignFirstResponder()
    }
    
    
    func changeCurrentLine2List() {
        let lineRange  = (text as NSString).lineRange(for: self.selectedRange)
        
        let line = getSelectedLine()
        
        if let bulletSymbolRange = highlightManager.bulletHightlighter.matchSymbol(text: self.text, lineRange: lineRange){
            // 移除 symbol
            replaceAndMoveSelected(range: NSMakeRange(bulletSymbolRange.location, bulletSymbolRange.length), replace: "")
            
        } else{
            
            let symbolStr = "- "
            let lineLeadingText = getLeadingText(line: line)
            
            if let numSymbolRange = highlightManager.numListHightlighter.matchSymbol(text: self.text, lineRange: lineRange)  {// 是
                
                let move = abs(numSymbolRange.length - symbolStr.count)
                
                
                replaceAndMoveSelected(range: NSMakeRange(lineRange.location, numSymbolRange.length), replace: symbolStr)
                
                
                self.tryUpdateBelowLinesNum(newBeginNum: 1, loc: lineRange.upperBound - move, lineLeadingText: lineLeadingText)
                
                return
            }
            
            replaceAndMoveSelected(range: NSMakeRange(lineRange.lowerBound, 0), replace: symbolStr)
        }
    }
}


//MARK:  UITextViewDelegate
extension MDTextViewWapper {
    
    public func handleEnterkey(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let lineRange  = getSelectedLineRange()
        let line = (textView.text as NSString).substring(with: lineRange)
        
        // 匹配
        if let numSymbolRange = highlightManager.numListHightlighter.matchSymbol(text: textView.text, lineRange: lineRange){
            let leadingText =  getLineLeadingText(line: line)
            self.handleNumberList(lineRange: lineRange, symbolRange: numSymbolRange,leadingText:leadingText)
            return false
        }
        
        if let bulletSymbolRange = highlightManager.bulletHightlighter.matchSymbol(text: textView.text, lineRange: lineRange){
            let leadingText =  getLineLeadingText(line: line)
            self.handleBulletList(lineRange: lineRange, symbolRange: bulletSymbolRange,leadingText:leadingText)
            return false
        }
        return true
    }
}


//MARK: 处理回车键
extension MDTextViewWapper {
    
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

//MARK: number list
extension MDTextViewWapper {
    
    func changeCurrentLine2OrderList() {
        let lineRange  = getSelectedLineRange()
        let line = getSelectedLine()
        
        let leadingText = getLeadingText(line: line)
        
        if let symbolRange = highlightManager.numListHightlighter.matchSymbol(text: self.text, lineRange: lineRange)  {
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
        
        if let bulletSymbolRange = highlightManager.bulletHightlighter.matchSymbol(text: self.text, lineRange: lineRange) {
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
            guard let symbolRange = highlightManager.numListHightlighter.matchSymbol(text: line, lineRange: NSMakeRange(0, line.count)) else {
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
              let symbolRange = highlightManager.numListHightlighter.matchSymbol(text: self.text, lineRange: preLineRange)
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
            guard let symbolRange = highlightManager.numListHightlighter.matchSymbol(text: line, lineRange: NSMakeRange(0, line.count)) else {
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

extension MDTextViewWapper {
    func getSelectedLineRange() -> NSRange {
        return (text as NSString).lineRange(for: self.selectedRange)
    }
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

//MARK: UITextViewDelegate
extension MDTextViewWapper: UITextViewDelegate {
    
    
    public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        guard let textView = self.textView else { return   nil }

        let glyphIndex = textView.layoutManager.glyphIndex(for: point, in: textView.textContainer)

        //Ensure the glyphIndex actually matches the point and isn't just the closest glyph to the point
        let glyphRect = textView.layoutManager.boundingRect(forGlyphRange: NSRange(location: glyphIndex, length: 1), in: textView.textContainer)
//        print("glyphIndex: \(glyphIndex)")
        if glyphIndex != 0 && glyphIndex < self.textStorage.length,
            glyphRect.contains(point),
            self.textStorage.attribute(NSAttributedString.Key.link, at: glyphIndex, effectiveRange: nil) != nil {

//            let last = self.text.substring(with:glyphIndex..<(glyphIndex+1))
//            if last == "\n" {
//                print("回车")
//                return nil
//            }
            
            if isForbid(){ return self.textView }

            let newText = clipText(characterIndex: glyphIndex)
            if  newText.first == "#" {
                if let range = self.highlightManager.tagHightlighter.firstMatch(text: newText, searchRange: NSMakeRange(0, newText.count)) {
                    let tag = newText.substring(with: range)
                    self.textviewTappedDelegate?.textViewTagTapped(textView, tag: tag)
                    print(tag)
                    return self.textView
                }
            }else {
                if let range = self.highlightManager.linkHightlighter.firstMatch(text: newText, searchRange: NSMakeRange(0, newText.count)) {
                    var link = newText.substring(with: range).lowercased()
                    if !link.starts(with: "http") {
                        link = "http://\(link)"
                    }
                    print(link)
                    self.textviewTappedDelegate?.textViewLinkTapped(textView, link: link)
                    return self.textView
                }
            }
        }
        return nil
    }
    
    func isForbid()  -> Bool {
        let newTime = Date().currentTimeMillis()
//        if tempTime ==  0  {
//            tempTime = newTime
//            return false
//        }
        if newTime - tempTime < 300 {
            return true
        }
        tempTime = newTime
        return false
    }
    
    func extractTag(characterIndex:Int) -> String? {
        let str = self.text.substring(to: characterIndex)
        let tagStart = str.lastIntIndex(of: "#")
        if tagStart == -1  { return nil}
        let newText  = self.text.substring(from: tagStart)

        guard let range = self.highlightManager.tagHightlighter.firstMatch(text: newText, searchRange: NSMakeRange(0, newText.count)) else { return nil}
        let tag = newText.substring(with: range)
        return tag
    }


    func extractLink(characterIndex:Int) -> String? {
        let str = self.text.substring(to: characterIndex)
        let start = str.lastIndex { $0 == "\n" || $0 == "\t" || $0 == " "}?.utf16Offset(in: str) ?? 0

        let newText  = self.text.substring(from: start)

        guard let range = self.highlightManager.linkHightlighter.firstMatch(text: newText, searchRange: NSMakeRange(0, newText.count)) else { return nil}
        let link = newText.substring(with: range)
        return link
    }


    func clipText(characterIndex:Int) -> String {
        let str = self.text.substring(to: characterIndex)
        let start = str.lastIndex { $0 == "\n" || $0 == "\t" || $0 == " "}?.utf16Offset(in: str) ?? -1

        let newText = self.text.substring(from: start+1)
        return newText
    }
}
