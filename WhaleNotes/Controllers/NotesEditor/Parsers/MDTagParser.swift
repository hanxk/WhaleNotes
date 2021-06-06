//
//  MDTagParser.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import MarkdownKit

class MDTagParser: MarkdownLink {
    
    init() {
        super.init()
        self.font = MDStyleConfig.boldFont
        self.color = .link
    }
    
    override var regex: String {
        return MDTagHighlighter.regexStr
    }
    
    override func match(_ match: NSTextCheckingResult,
                        attributedString: NSMutableAttributedString) {
        let tagName = attributedString.attributedSubstring(from: match.range(at: 0)).string
        attributedString.addAttribute(.tag, value: tagName, range: match.range)
        addAttributes(attributedString, range: match.range, link: tagName)
    }
}
