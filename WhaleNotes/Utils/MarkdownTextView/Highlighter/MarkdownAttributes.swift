//
//  MarkdownAttributes.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/28/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

/**
*  Encapsulates the attributes to use for styling various types
*  of Markdown elements.
*/

let lineHeight:CGFloat = 30
let defaultFont = MarkdownAttributes.MonospaceFont
//let fontName  = "Avenir Next"
public struct MarkdownAttributes {
    
    private static let paragraphStyle = { () -> NSMutableParagraphStyle in
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.lineHeightMultiple = 1.2
        return paraStyle
    }()
    public var defaultAttributes: TextAttributes!
    
    static let mdDefaultAttributes:TextAttributes = [
        .font: defaultFont,
        .foregroundColor: UIColor.primaryText,
        .paragraphStyle: MarkdownAttributes.paragraphStyle
    ]
    
    public init() {
        self.defaultAttributes = MarkdownAttributes.mdDefaultAttributes
    }
    
    public var strongAttributes: TextAttributes?
    public var emphasisAttributes: TextAttributes?
    
    public struct HeaderAttributes {
        public var h1Attributes: TextAttributes? = [
            .font:headerFont,
                .foregroundColor: UIColor.primaryText
        ]
        
        public var h2Attributes: TextAttributes? = [
            .font:headerFont
        ]
        
        public var h3Attributes: TextAttributes? = [
            .font: headerFont
        ]
        
        public var h4Attributes: TextAttributes? = [
            .font: fontWithTraits(traits: .traitBold, font: UIFont.preferredFont(forTextStyle: .subheadline))
        ]
        
        public var h5Attributes: TextAttributes? = [
            .font: fontWithTraits(traits: .traitBold, font: UIFont.preferredFont(forTextStyle: .subheadline))
        ]
        
        public var h6Attributes: TextAttributes? = [
            .font: fontWithTraits(traits: .traitBold, font: UIFont.preferredFont(forTextStyle: .subheadline))
        ]
        
        func attributesForHeaderLevel(level: Int) -> TextAttributes? {
            switch level {
            case 1: return h1Attributes
            case 2: return h2Attributes
            case 3: return h3Attributes
            case 4: return h4Attributes
            case 5: return h5Attributes
            case 6: return h6Attributes
            default: return nil
            }
        }
        
        public init() {}
    }
    
    public var headerAttributes: HeaderAttributes? = HeaderAttributes()
    
     static let MonospaceFont: UIFont = {
//        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let size:CGFloat = 16
//        return bodyFont
//        return UIFont(name:fontName,size: size)!
        return UIFont.systemFont(ofSize: size)
//        return UIFont(name:"Courier",size: size)!
//        return UIFont(name: "Menlo", size: size) ?? UIFont(name: "Courier", size: size) ?? bodyFont
    }()
    
    
     static let headerFont: UIFont = {
//        let headerFont = UIFont.preferredFont(forTextStyle: .headline)
//        let size = headerFont.pointSize
//        let font =  UIFont(name:fontName,size: size) ?? UIFont.systemFont(ofSize: size)
        return fontWithTraits(traits: .traitBold, font: defaultFont)
    }()
    static let headerFont2: UIFont = {
//        let headerFont = UIFont.preferredFont(forTextStyle: .headline)
        let size:CGFloat =  20
//       let font =  UIFont(name:fontName,size: size) ?? UIFont.systemFont(ofSize: size)
       return fontWithTraits(traits: .traitBold, font: font)
   }()
    
    public var codeBlockAttributes: TextAttributes? = [
        .font: MarkdownAttributes.MonospaceFont
    ]
    
    public var inlineCodeAttributes: TextAttributes? = [
        .font: MarkdownAttributes.MonospaceFont
    ]
    
    public var blockQuoteAttributes: TextAttributes? = [
        .foregroundColor: UIColor.darkGray
    ]
    //fontWithTraits(traits: .traitBold, font:  UIFont.preferredFont(forTextStyle: .body))
    public var orderedListAttributes: TextAttributes? = [
        .font:UIFont.preferredFont(forTextStyle: .body),
    ]
    
    public var tagAttributes: TextAttributes? = [
        .font:defaultFont,
//        .foregroundColor: UIColor(hexString: "#175199"), #175199
//        .foregroundColor:UIColor.red,
        NSAttributedString.Key.foregroundColor: UIColor.green,
        NSAttributedString.Key.underlineColor: UIColor.lightGray,
        NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
//        .backgroundColor:UIColor(hexString: "#175199").withAlphaComponent(0.6)
//        .foregroundColor: UIColor.white,
//        .backgroundStyle:BackgroundStyle(color: .blue)
    ]
    
    
    public var orderedListItemAttributes: TextAttributes? = [
        .font:UIFont.preferredFont(forTextStyle: .body),
    ]
    
    public var unorderedListAttributes: TextAttributes? = [
        .font: UIFont.preferredFont(forTextStyle: .body),
    ]
    
    public var unorderedListItemAttributes: TextAttributes? = [
        .font:  UIFont.preferredFont(forTextStyle: .body),
    ]
    
}
