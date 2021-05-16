//
//  MDLinkParser.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import MarkdownKit

class MDLinkParser: MarkdownLink {
    
    open override func regularExpression() throws -> NSRegularExpression {
       return try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
     }
     
     open override func match(_ match: NSTextCheckingResult,
                                attributedString: NSMutableAttributedString) {
       var linkURLString = attributedString.attributedSubstring(from: match.range).string
        
        if linkURLString.contains("://") == false {
            linkURLString = "https://"+linkURLString
        }
        
       formatText(attributedString, range: match.range, link: linkURLString)
       addAttributes(attributedString, range: match.range, link: linkURLString)
        
        attributedString.addAttributes([.underlineStyle:0,.underlineColor:UIColor.clear], range: match.range)
//        attributedString.addAttribute(.underlineStyle, value: 0, range: match.range)
//        attributedString.addAttributes([
//            [.underlineStyle: 0, .underlineColor: UIColor.clear]
//        ], range: <#T##NSRange#>)
//        attributedString.addAttribute(.underlineStyle:0,value: url, range: range)
//        textView.linkTextAttributes = [.underlineStyle: 0, .underlineColor: UIColor.clear,]
     }
  
}
