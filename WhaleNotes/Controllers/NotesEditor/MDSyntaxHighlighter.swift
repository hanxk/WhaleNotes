//
//  HighlightManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/11.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

let paragraphStyle = { () -> NSMutableParagraphStyle in
    let paraStyle = NSMutableParagraphStyle()
//    paraStyle.lineSpacing = MDEditStyleConfig.lineSpacing
//    lineHeightMultiple
    paraStyle.lineHeightMultiple = 1.2
//    paragraphStyle.lineHeightMultiple = MDStyleConfig.lineHeight
//    paraStyle.maximumLineHeight = MDStyleConfig.lineHeight
//    paraStyle.minimumLineHeight = MDStyleConfig.lineHeight
    return paraStyle
}()

enum MDStyleConfig {
    static let headerFont:UIFont = UIFont.systemFont(ofSize: 18,weight: .medium)
    static let boldFont:UIFont = UIFont.systemFont(ofSize: 16,weight: .medium)
    static let normalFont:UIFont = UIFont.systemFont(ofSize: 16)
    static let lineSpacing:CGFloat = 4
}
enum MDEditStyleConfig {
    static let headerFont:UIFont = UIFont.systemFont(ofSize: 20,weight: .medium)
    static let boldFont:UIFont = UIFont.systemFont(ofSize: 17,weight: .medium)
    static let normalFont:UIFont = UIFont.systemFont(ofSize: 17)
    static let lineSpacing:CGFloat = 5
}

struct HighlightStyle {
    var textColor: UIColor
    var backgroundColor: UIColor = .clear
    var italic: Bool = false
    var deletionLine: Bool = false
    var font:UIFont!
    
    init(font:UIFont = MDStyleConfig.normalFont,textColor:UIColor = .primaryText) {
        self.font = font
        self.textColor = textColor
    }

    var attrs: [NSAttributedString.Key : Any] {
        
        return [NSAttributedString.Key.font : font!,
//                .obliqueness : italic ? 0.3 : 0,
                .foregroundColor : textColor,
//                .backgroundColor : backgroundColor,
//                .strikethroughStyle : deletionLine ? NSUnderlineStyle.single.rawValue :  NSUnderlineStyle.init().rawValue,
//                .strikethroughColor : textColor,
                .paragraphStyle : paragraphStyle
        ]
    }
}

struct Syntax {
    let expression: NSRegularExpression
    let style: HighlightStyle
    let pattern:String
    
    init(_ pattern: String,style:HighlightStyle, options: NSRegularExpression.Options = .anchorsMatchLines) {
        expression = try! NSRegularExpression(pattern: pattern, options: options)
        self.style = style
        self.pattern = pattern
    }
    
    func isMatch(text:String) -> Bool {
        return expression.firstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range:  NSMakeRange(0, text.count)) != nil
    }
    
    
    func match(text:String,range:NSRange) -> NSRange? {
        let range = expression.rangeOfFirstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: range)
        if range.location == NSNotFound {
            return nil
        }
        return range
    }
    
    //allrange,symbol range
    func matchAllRange(text:String,range:NSRange) -> (NSRange,NSRange)? {
//        let range = expression.rangeOfFirstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: range)
//        if range.location == NSNotFound {
//            return nil
//        }
       if let match = expression.firstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: range) {
            return (match.range,match.range(at: 1))
       }
       return nil
    }
    
//    func matchSymbol(text:String,range:NSRange) -> NSRange? {
//        let range = expression.rangeOfFirstMatch(in: text, options: NSRegularExpression.MatchingOptions(), range: range)
//        if range.location == NSNotFound {
//            return nil
//        }
//        return range
//    }
    
    func matchSymbol(text:String,symbolEnd:Character = " ") -> String? {
        if !isMatch(text: text) { return nil }
        if let index = text.firstIndex(of: symbolEnd) {
            return text.subString(to: index)
        }
        return nil
    }
}

struct MDSyntaxHighlighter {
    var isEdit:Bool
    
    let headerSyntax:Syntax!
    let boldSyntax:Syntax!
    let tagSyntax:Syntax!
    let bulletSyntax:Syntax!
    let numberSyntax:Syntax!
    let syntaxArray: [Syntax]!
    
    static let normalStyle = HighlightStyle(font: MDEditStyleConfig.normalFont)
    
    init(isEdit:Bool=true) {
        self.isEdit = isEdit
        headerSyntax =  Syntax("^#{1,6} .*", style: HighlightStyle(font: MDEditStyleConfig.headerFont))
        boldSyntax =  Syntax(#"(?<=(.?|^))(\*{2})(?=\S)(.+?)(?<=\S)(\2)"#, style: HighlightStyle(font: MDEditStyleConfig.boldFont))
        bulletSyntax = Syntax(#"^(?:[ \t]*)([\*\+\-])(?:[ ])(?:.*)$"#,style:HighlightStyle(font: MDEditStyleConfig.normalFont))
        numberSyntax = Syntax(#"^(?:[ \t]*)(\d+)[.][ \t]+(?:.*)$"#,style: HighlightStyle(font: MDEditStyleConfig.normalFont))
        tagSyntax =  Syntax(MDTagHighlighter.regexStr,style: HighlightStyle(font: MDEditStyleConfig.normalFont,textColor: .link))
        syntaxArray = [headerSyntax,bulletSyntax,numberSyntax,tagSyntax,boldSyntax]
    }
    
    func highlight(_ text: NSTextStorage, visibleRange: NSRange? = nil) {
        let len = (text.string as NSString).length
        if len == 0 { return }
        var validRange:NSRange
        if  let  visibleRange = visibleRange {
            validRange = visibleRange
        }else {
            validRange  = NSRange(location:0, length: len)
        }
        
        text.setAttributes(MDSyntaxHighlighter.normalStyle.attrs, range: validRange)
        
        syntaxArray.forEach { (syntax) in
            syntax.expression.enumerateMatches(in: text.string, options: .reportCompletion, range: validRange, using: { (match, _, _) in
                if let range = match?.range {
                    text.addAttributes(syntax.style.attrs, range: range)
                }
            })
        }
    }
    
//    func getTextStyleAttributes() -> [NSAttributedString.Key : Any] {
//        let nomarlColor = UIColor.primaryText
//        return [.font : MDEditStyleConfig.normalFont,
//                .paragraphStyle : paragraphStyle,
//                .foregroundColor : nomarlColor]
//    }
    
}
