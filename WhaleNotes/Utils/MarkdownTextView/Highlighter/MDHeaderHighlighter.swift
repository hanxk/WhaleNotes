//
//  MDHeaderHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/31.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

public final class MDHeaderHighlighter: MDHighlighterType {
    private let headerRegex:NSRegularExpression
    private let attributes:TextAttributes
    init(maxLevel:Int) {
        self.headerRegex = regexFromPattern(pattern: "^(#{1,\(maxLevel)})\\s+(.*)$")
        self.attributes = MarkdownAttributes.HeaderAttributes().attributesForHeaderLevel(level:1)!
    }
    
    public func highlight(storage:MarkdownTextStorage,searchRange:NSRange) {
        self.headerRegex.enumerateMatches(in: storage.string, range: searchRange) {
            match, flags, stop in
            if  let  match = match {
                storage.addAttributes(attributes, range: match.range)
            }
        }
    }
}
