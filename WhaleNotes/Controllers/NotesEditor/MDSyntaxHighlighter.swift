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
    paraStyle.lineSpacing = MDEditStyleConfig.lineSpacing
//    paraStyle.lineHeightMultiple = MDStyleConfig.lineHeight
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
    static let headerFont:UIFont = UIFont.systemFont(ofSize: 19,weight: .medium)
    static let boldFont:UIFont = UIFont.systemFont(ofSize: 17,weight: .medium)
    static let normalFont:UIFont = UIFont.systemFont(ofSize: 17)
    static let lineSpacing:CGFloat = 5
}

struct HighlightStyle {
    var textColor: UIColor = UIColor.primaryText
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
                .obliqueness : italic ? 0.3 : 0,
                .foregroundColor : textColor,
                .backgroundColor : backgroundColor,
                .strikethroughStyle : deletionLine ? NSUnderlineStyle.single.rawValue :  NSUnderlineStyle.init().rawValue,
                .strikethroughColor : textColor,
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
}

struct MDSyntaxHighlighter {
    var isEdit:Bool
    init(isEdit:Bool=true) {
        self.isEdit = isEdit
    }
    
    let normalStyle = HighlightStyle(font: MDEditStyleConfig.normalFont)
    
    let syntaxArray: [Syntax] = [
        Syntax("^#{1,6} .*", style: HighlightStyle(font: MDEditStyleConfig.headerFont)),
        Syntax("^.*\\n={2,}$",style:HighlightStyle(font: MDEditStyleConfig.normalFont)),
        Syntax(MDTagHighlighter.regexStr,style: HighlightStyle(font: MDEditStyleConfig.normalFont,textColor: .link)),
        Syntax("- \\[( |x)\\] .*",style:HighlightStyle(font: MDEditStyleConfig.normalFont)),
        Syntax("^.*\\n-{2,}$", style:HighlightStyle(font: MDEditStyleConfig.normalFont)),
        Syntax("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) ",style: HighlightStyle(font: MDEditStyleConfig.normalFont))
    ]
    
    func highlight(_ text: NSTextStorage, visibleRange: NSRange? = nil) {
        let len = (text.string as NSString).length
        var validRange:NSRange
        if  let  visibleRange = visibleRange {
            validRange = visibleRange
        }else {
            validRange  = NSRange(location:0, length: len)
        }
        
        text.setAttributes(getTextStyleAttributes(), range: validRange)
        
        syntaxArray.forEach { (syntax) in
            syntax.expression.enumerateMatches(in: text.string, options: .reportCompletion, range: validRange, using: { (match, _, _) in
                if let range = match?.range {
                    text.addAttributes(syntax.style.attrs, range: range)
                }
            })
        }
    }
    
    func getTextStyleAttributes() -> [NSAttributedString.Key : Any] {
        let nomarlColor = UIColor.primaryText
        return [.font : MDEditStyleConfig.normalFont,
                .paragraphStyle : paragraphStyle,
                .foregroundColor : nomarlColor]
    }
    
}
