//
//  MarkdownListHighlighter.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/29/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

/**
*  Highlights Markdown lists using specifiable marker patterns.
*/
public final class MarkdownListHighlighter: HighlighterType {
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

extension MarkdownListHighlighter {
    
    func getSymbolRange(text: String) ->Range<String.Index>?  {
        let matchRange = text.range(of: #"(?:(?:[*+-])[ ])"#,
                                       options: .regularExpression) //.utf16Offset(in: self)
        return matchRange
    }
    
    func getSymbolNSRange(text: String) -> NSRange?  {
        guard let matchRange = text.range(of: #"(?:(?:[*+-])[ ])"#) else { return nil }
        return matchRange
    }
}
