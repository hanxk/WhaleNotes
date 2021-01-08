//
//  MDLinkHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/6.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

public final class MDLinkHighlighter: MDHighlighterType {
    
    let regex:NSRegularExpression
    private let attributes:TextAttributes
    private let regexStr = #"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})"#
    //(?:^|(?<=\\s+))(?:#)(\\S+)(?=\\s+)"
    init() {
        self.regex = regexFromPattern(pattern: regexStr)
        self.attributes = MarkdownAttributes().tagAttributes!
    }
    
    
    public func highlight(storage:NSTextStorage,searchRange:NSRange) {
        self.regex.enumerateMatches(in: storage.string, range: searchRange) {
            match, flags, stop in
            if  let  match = match {
                storage.addAttribute(.link, value: attributes, range: match.range(at: 0))
            }
        }
    }
    
    func firstMatch(text:String,searchRange:NSRange) -> NSRange?  {
        
        guard let range = self.regex.firstMatch(in: text, options: [], range: searchRange) else { return nil }
        return range.range(at: 0)
    }
}
