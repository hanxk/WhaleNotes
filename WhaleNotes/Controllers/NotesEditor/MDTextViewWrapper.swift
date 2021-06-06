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
    
    var text:String {
        return textView?.text ?? ""
    }
    
    
    
    var selectedRange:NSRange {
        return textView?.selectedRange ?? NSRange.init()
    }
    
    init(textView:UITextView) {
        super.init()
        textView.isSelectable = true
        self.textView = textView
        self.textView?.delegate = self
    }
}

extension MDTextViewWrapper: UITextViewDelegate {
    
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
            textView.insertText(newText)
//            textView.replace(textRange, withText: newText)
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
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
    
    func newLine(_ last: String) -> String{
        let line = "\n"
        if highlight.bulletSyntax.isMatch(text: last) {
            return line + "- "
        }
        
        if let numberSymbol = highlight.numberSyntax.matchSymbol(text: last,symbolEnd: "."),
           let number = Int(numberSymbol){
            return line +  String(number + 1)+". "
        }
        
        return line
    }
    
    func newLine2(_ last: String) -> String {
        if last.hasPrefix("- [x] ") {
            return last + "\n- [x] "
        }
        if last.hasPrefix("- [ ] ") {
            return last + "\n- [ ] "
        }
        if let str = last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) ") {
            if last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) +[\\S]+") == nil {
                return ""
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
    
    func changeHeaderLine() {
        let lineRange  = (text as NSString).lineRange(for: selectedRange)
        let line = getSelectedLine()
        
        var tagApend = ""
        if let _ = matchHeaderSymbol(text: line, lineRange: NSMakeRange(0, line.count)) {
            tagApend = HASHTAG
        }else {
            tagApend = HASHTAG + " "
        }
        self.textView?.textStorage.replaceCharacters(in: NSMakeRange(lineRange.lowerBound, 0), with: tagApend)
        textView?.selectedRange = NSMakeRange(selectedRange.location+tagApend.count, 0)
        self.processHighlight()
    }
    
    func changeCurrentLine2List() {
        let lineRange  = (text as NSString).lineRange(for: selectedRange)
        let line = getSelectedLine()
        
        if highlight.bulletSyntax.isMatch(text: line){
            // 移除 symbol
            replaceAndMoveSelected(range: NSMakeRange(lineRange.location,2), replace: "")
            return
        }
        
        let symbolStr = "- "
//        let lineLeadingText = getLeadingText(line: line)
        
        if highlight.numberSyntax.isMatch(text: line)  {
//            let move = abs(numSymbolRange.length - symbolStr.count)
//            replaceAndMoveSelected(range: NSMakeRange(lineRange.location, numSymbolRange.length), replace: symbolStr)
            replaceAndMoveSelected(range: NSMakeRange(lineRange.lowerBound,1), replace: "")
//            self.tryUpdateBelowLinesNum(newBeginNum: 1, loc: lineRange.upperBound - move, lineLeadingText: lineLeadingText)
            return
        }
        
        replaceAndMoveSelected(range: NSMakeRange(lineRange.lowerBound, 0), replace: symbolStr)
        self.processHighlight()
        
    }
    
    private func getLeadingText(line: String)-> String {
        
        var leadingLength = 0
        if let r =  line.leadingWhiteSpaceAndTabRange() {
            leadingLength = r.length
        }
        let leadingText = line.subString(to: leadingLength)
        return  leadingText
    }
    
    
    func matchHeaderSymbol(text:String,lineRange:NSRange) -> (NSRange)? {
        let regex = regexFromPattern(pattern: MDHeaderCommon.regexStr)
        if let match = regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: lineRange) {
            if match.range.location != NSNotFound {
                var range = match.range(at: 1)
                range.length += 1
                return range
            }
        }
        return nil
    }
    
    func matchBulletSymbol(text:String,lineRange:NSRange) -> (NSRange)? {
        let regex = regexFromPattern(pattern: MDBulletListHighlighter.regexStr)
        if let match = regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: lineRange) {
            if match.range.location != NSNotFound {
                var range = match.range(at: 1)
                range.length += 1
                return range
            }
        }
        return nil
    }
    
    
    func matchListSymbol(text:String,lineRange:NSRange) -> (NSRange)? {
        let regex = regexFromPattern(pattern: MDNumListHighlighter.regexStr)
        if let match = regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: lineRange) {
            if match.range.location != NSNotFound {
                let range = match.range(at: 1)
                //                range.length += 1
                return range
            }
        }
        return nil
    }
    
    
    func replaceAndMoveSelected(range:NSRange,replace:String) {
        
        let move = range.length - replace.length
        guard let textView = self.textView else { return }
        
        let newSelected = textView.selectedRange.location-move
        textView.textStorage.replaceCharacters(in: range, with: replace)
        textView.selectedRange = NSMakeRange(newSelected, 0)
    }
    
    
    func tryUpdateBelowLinesNum(newBeginNum:Int,loc:Int,lineLeadingText:String)  {
        let otherText = self.text.substring(from: loc)
        let lines = otherText.components(separatedBy: ENTER_KEY.toString)
        
        var lineNum = newBeginNum
        var newLoc = loc
        
        for line in lines  {
            guard let symbolRange = matchListSymbol(text: line, lineRange: NSMakeRange(0, line.count)) else {
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
            self.textView!.textStorage.replaceCharacters(in: NSMakeRange(newLoc, symbolRange.length), with: symbolStr)
            
            // 更新后新的行
            let newLineCount = line.count - (symbolRange.length - symbolStr.count)
            newLoc = newLoc +  newLineCount  +  1    //+1 是换行符
            lineNum += 1
        }
    }
}


//MARK: number list
extension MDTextViewWrapper {
    
    func changeCurrentLine2OrderList() {
        let lineRange  = getSelectedLineRange()
        let line = getSelectedLine()
        
        let leadingText = getLeadingText(line: line)
        
        if let symbolRange = matchListSymbol(text: self.text, lineRange: lineRange)  {
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
        
        if let bulletSymbolRange = matchBulletSymbol(text: self.text, lineRange: lineRange) {
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
        let preText = self.text.subString(to: lineRange.location-1) // -1 是过滤掉回车
        let lines = Array(preText.components(separatedBy: ENTER_KEY.toString).reversed())
        for line in lines {
            guard let symbolRange = matchListSymbol(text: line, lineRange: NSMakeRange(0, line.count)) else {
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
    
    func getSymbolNum() -> Int {
        guard let preLineRange = getSelectedPreLineRange(),
              let symbolRange = matchListSymbol(text: self.text, lineRange: preLineRange)
        else { return 1}
        let index = symbolRange.upperBound - 1
        let num = (self.text.substring(with: symbolRange.location..<index) as NSString).integerValue
        return num + 1
    }
    
}

extension MDTextViewWrapper {
    func getSelectedLineRange() -> NSRange {
        return (text as NSString).lineRange(for: self.textView!.selectedRange)
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
