//
//  MarkdownOrderListHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/28.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

/**
*  Highlights Markdown lists using specifiable marker patterns.
*/
public final class MarkdownOrderListHighlighter: HighlighterType {
    private let regularExpression: NSRegularExpression
    private let attributes: TextAttributes?
    private let itemAttributes: TextAttributes?
    
    /**
    Creates a new instance of the receiver.
    
    :param: markerPattern  Regular expression pattern to use for matching
    list markers.
    :param: attributes     Attributes to apply to the entire list.
    :param: itemAttributes Attributes to apply to list items (excluding
    list markers)
    
    :returns: An initialized instance of the receiver.
    */
    public init(markerPattern: String, attributes: TextAttributes?, itemAttributes: TextAttributes?) {
        self.regularExpression = listItemRegexWithMarkerPattern(pattern: markerPattern)
        self.attributes = attributes
        self.itemAttributes = itemAttributes
    }
    
    // MARK: HighlighterType
    
    public func highlightAttributedString(attributedString: NSMutableAttributedString) {
        if (attributes == nil && itemAttributes == nil) { return }
        
        enumerateMatches(regex: regularExpression, string: attributedString.string) {
            if let attributes = self.attributes {
                attributedString.addAttributes(attributes, range: $0.range)
            }
            if let itemAttributes = self.itemAttributes {
                attributedString.addAttributes(itemAttributes, range: $0.range(at: 1))
            }
        }
    }
    
    func match(text:String) -> Bool {
        let matches = regularExpression.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches.count > 0
    }
}

private func listItemRegexWithMarkerPattern(pattern: String) -> NSRegularExpression {
    // From markdown.pl v1.0.1 <http://daringfireball.net/projects/markdown/>
    return regexFromPattern(pattern: "^(?:[ ]{0,3}(?:\(pattern))[ \t]+)(.*)")
    
    //v [*+-]  ^(?:[ ]{0,3}(?:[*+-])[ \t]+)(.+)  - \\[( |x)\\] .*
//    return regexFromPattern(pattern: "- \\[( |x)\\] .*")
    
}



extension MarkdownOrderListHighlighter {
    
    func handleOrderListInput(textStorage:MarkdownTextStorage,lineText: String,inputText:String,range:NSRange, offset: Int) {
        
        let isNumOnly = lineText.firstIntIndex(of: ".") == lineText.utf16Count - 2
        if isNumOnly {//最后一行,并且只有一个符号
            let replaceRange = NSMakeRange(range.location-lineText.utf16Count, lineText.utf16Count+1)
            textStorage.replaceCharactersInRange(replaceRange, withString: "", selectedRangeLocationMove: -1)
            
            let cursorPos = replaceRange.location
            tryUpdateOtherOrderList(textStorage:textStorage,cursorPos: cursorPos, numBegin: 1)
            return
        }
        let pointIndex = lineText.firstIndex(of: ".")!.utf16Offset(in: lineText)
        let numPrefix = NSString(string: lineText.substring(with: (0..<pointIndex))).integerValue+1
        let prefix = "\(numPrefix). "
        let newText = ENTER_KEY.toString() + prefix
        let newRange = NSMakeRange(range.location, 1)
        let move = newText.count - 1
        textStorage.replaceCharactersInRange(newRange, withString: newText,selectedRangeLocationMove: move)
        
        //更新其它行
        let cursorPos = newRange.location + move
        tryUpdateOtherOrderList(textStorage:textStorage,cursorPos: cursorPos, numBegin: numPrefix+1)
        
    }
    
    //更新其它行
    func tryUpdateOtherOrderList(textStorage:MarkdownTextStorage,cursorPos:Int,numBegin:Int) {
        
        let lines = textStorage.string.substring(from: cursorPos).components(separatedBy: ENTER_KEY.toString())
        if lines.count == 1 { return }
        
        
        let otherLines = lines.dropFirst()
        
        var firstLineStart  = cursorPos + lines[0].count + 1
        var firstLineNum = numBegin
        
        for lineText in otherLines {
            print("* \(lineText)")
            if !match(text: lineText) {
                break
            }
            let oldStrCount = textStorage.string.count
            updateOrderListLine(textStorage:textStorage,lineStarIndex: firstLineStart, lineText: lineText, newNum: firstLineNum)
            
            // 更新当前行的索引
            firstLineStart = firstLineStart+lineText.count+(textStorage.string.count-oldStrCount)+1
            firstLineNum += 1
        }
    }
    
    private func updateOrderListLine(textStorage:MarkdownTextStorage,lineStarIndex:Int,lineText:String,newNum:Int)  {
        let offset  =  lineText.firstIndex(of: ".")!.utf16Offset(in: lineText)
        let newRange = NSMakeRange(lineStarIndex, offset)
        textStorage.replaceCharactersInRange(newRange, withString: String(newNum))
    }
}

extension MarkdownOrderListHighlighter {
    
    func getSymbolRange(text: String) ->Range<String.Index>?  {
        let matchRange = text.range(of: #"(?:(?:\d+[.])[ ])"#,
                                       options: .regularExpression) //.utf16Offset(in: self)
        return matchRange
    }
    
    func getSymbolNSRange(text: String) -> NSRange?  {
        guard let matchRange = text.range(of: #"(?:(?:\d+[.])[ \t]+)(.*)"#) else { return nil }
        return matchRange
    }
}
