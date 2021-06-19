//
//  MDParser.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import MarkdownKit

class  MDParser {
    
    private var mdParser:MarkdownParser!
    static var shared = MDParser()
    
    private init() {
        mdParser = MarkdownParser(font: UIFont.systemFont(ofSize: 16),color: UIColor.primaryText)
        mdParser.enabledElements = [.list,.bold]
        mdParser.bold.color = .primaryText
        mdParser.customElements = [MDHeaderCommon(),MDTagParser(),MDLinkParser(font: MDStyleConfig.normalFont,color: .link)]
    }
    
    func parse(markdown:String) -> NSAttributedString {
        let attrString = mdParser.parse(markdown) as! NSMutableAttributedString
        attrString.setLineSpacing(MDStyleConfig.lineSpacing)
        return attrString
    }
}



class MarkdownHeaderCommon2: MarkdownElement {
    open var regex: String {
        return #"(?<=\s|^)#([^#\s]+(?:(?: *[^#\s]+)*#)?)"#
    }
    
    //    private let regex = #"(?<=\s|^)#([^#\s]+(?:(?: *[^#\s]+)*#)?)"#
    func regularExpression() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: regex, options: .dotMatchesLineSeparators)
    }
    
    func match(_ match: NSTextCheckingResult, attributedString: NSMutableAttributedString) {
        
    }
    
    //      override func match(_ match: NSTextCheckingResult,
    //                               attributedString: NSMutableAttributedString) {
    //  //        let subredditName = attributedString.attributedSubstring(from: match.rangeAtIndex(3)).string
    //  //    let linkURLString = "http://reddit.com/r/\(subredditName)"
    //  //    formatText(attributedString, range: match.range, link: "123123")
    //      addAttributes(attributedString, range: match.range, link: "123123123")
    //    }
    
    
}
extension UIFont {
    
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont? {
        guard let descriptor = fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits)) else {
            return nil
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
    func bold() -> UIFont? {
        return withTraits(.traitBold)
    }
    
    func italic() -> UIFont? {
        return withTraits(.traitItalic)
    }
}



public extension NSAttributedString.Key {
    static let tag = NSAttributedString.Key("tag")
}
