//
//  MDTagHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation

public final class MDTagHighlighter: MDHighlighterType {
    
    let regex:NSRegularExpression
    private let attributes:TextAttributes
    private let regexStr = "(?:^|\\s)(?:#)(\\S+)(?:$|(?=\\s?))"
    //(?:^|(?<=\\s+))(?:#)(\\S+)(?=\\s+)"
    init() {
        self.regex = regexFromPattern(pattern: regexStr)
        self.attributes = MarkdownAttributes().tagAttributes!
    }
    
    
    public func highlight(storage:MarkdownTextStorage,searchRange:NSRange) {
        self.regex.enumerateMatches(in: storage.string, range: searchRange) {
            match, flags, stop in
            if  let  match = match {
                storage.addAttribute(.link, value: attributes, range: match.range(at: 0))
//                storage.addAttributes(attributes, range: match.range)
            }
        }
    }
    
    func firstMatch(text:String,searchRange:NSRange) -> NSRange?  {
        guard let range = self.regex.firstMatch(in: text, options: [], range: searchRange) else { return nil }
        return range.range(at: 1)
    }
}
