//
//  MDNumListHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/2.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation

public final class MDNumListHighlighter: MDHighlighterType {
    private let regex:NSRegularExpression
    private let attributes:TextAttributes
    private let regexStr = "^(?:[ \\t]*)(\\d+[.][ \\t]+)(?:.*)$"
    
    init() {
        self.regex = regexFromPattern(pattern: regexStr)
        self.attributes = MarkdownAttributes().orderedListAttributes!
    }
    
    public func highlight(storage:MarkdownTextStorage,searchRange:NSRange) {
        self.regex.enumerateMatches(in: storage.string, range: searchRange) {
            match, flags, stop in
            if  let  match = match {
                storage.addAttributes(attributes, range: match.range)
            }
        }
    }
    
    //匹配当前行的range 和 sybol range
    //_ _ 1. 123
    func match(line:String) -> (NSRange,NSRange)? {
        let range = NSMakeRange(0, line.length)
        if let match = regex.firstMatch(in: line as String, options: NSRegularExpression.MatchingOptions(), range: range) {
            if match.range.location != NSNotFound {
                return (match.range(at: 0),match.range(at: 1))
            }
        }
        return nil
    }
    
    
    func matchSymbol(text:String,lineRange:NSRange) -> (NSRange)? {
        if let match = regex.firstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: lineRange) {
            if match.range.location != NSNotFound {
                return match.range(at: 1)
            }
        }
        return nil
    }
}
