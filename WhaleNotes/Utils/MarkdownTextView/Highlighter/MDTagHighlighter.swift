//
//  MDTagHighlighter.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

public final class MDTagHighlighter: MDHighlighterType {
    
    let regex:NSRegularExpression
    private let attributes:TextAttributes
    static let regexStr = #"\B#([^#\/\s]+(?:\/[^#\/\s]*)*)(?=\s|$)"#
//    static let regexStr = #"\B#[^#\/\s]+(\/[^#\/\s]*)*(?=\s|$)"#
//    static let regexStr = "(?:^|\\s)(?:#)(\\S+)(?:$|(?=\\s?))"
    
    
    init(font:  UIFont) {
        self.regex = regexFromPattern(pattern: MDTagHighlighter.regexStr)
        self.attributes =  [
            .font:font,
            NSAttributedString.Key.foregroundColor: UIColor.red
        ]
    }
    
//    public var tagAttributes: TextAttributes? = [
//        .font:defaultFont,
//        NSAttributedString.Key.foregroundColor: UIColor.green,
//        NSAttributedString.Key.underlineColor: UIColor.lightGray,
//        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
//    ]
    
    public func highlight(storage:NSTextStorage,searchRange:NSRange) {
        self.regex.enumerateMatches(in: storage.string, range: searchRange) {
            match, flags, stop in
            if  let  match = match {
//                storage.addAttribute(.tagStyle,value: TagStyle(),range: match.range(at: 0))
//                storage.addAttribute(.,value: TagStyle(),range: match.range(at: 0))
//                storage.addAttribute(.link, value: attributes, range: match.range(at: 0))
                storage.addAttribute(.link, value: attributes, range:  match.range)
                storage.addAttributes(attributes, range: match.range)
//                storage.addAttribute(., value: <#T##Any#>, range: <#T##NSRange#>)
            }
        }
    }
    
    func firstMatch(text:String,searchRange:NSRange) -> NSRange?  {
        guard let range = self.regex.firstMatch(in: text, options: [], range: searchRange) else { return nil }
        return range.range(at: 1)
    }
}
