//
//  MDListHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/31.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

public final class MDBulletListHighlighter: MDHighlighterType {
    private let regex:NSRegularExpression
    private let attributes:TextAttributes
    private let regexStr = "(?:[\\*\\+\\-])\\s.*$"
    //^(?:[ \t]*(?:[*+-])    ^[ \t]*([\*\+\-])\s+(.*)$
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
    
    func match(line:String) -> NSRange? {
        let range = NSMakeRange(0, line.length)
        if let match = regex.firstMatch(in: line as String, options: NSRegularExpression.MatchingOptions(), range: range) {
            if match.range.location != NSNotFound {
                return match.range(at: 0)
            }
        }
        return nil
    }
}
