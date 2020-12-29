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
public struct MarkdownAttributes {
    public var defaultAttributes: TextAttributes = [
        .font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
    ]
    
    public var strongAttributes: TextAttributes?
    public var emphasisAttributes: TextAttributes?
    
    public struct HeaderAttributes {
        public var h1Attributes: TextAttributes? = [
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]
        
        public var h2Attributes: TextAttributes? = [
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]
        
        public var h3Attributes: TextAttributes? = [
            .font: UIFont.preferredFont(forTextStyle: .headline)
        ]
        
        public var h4Attributes: TextAttributes? = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline)
        ]
        
        public var h5Attributes: TextAttributes? = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline)
        ]
        
        public var h6Attributes: TextAttributes? = [
            .font: UIFont.preferredFont(forTextStyle: .subheadline)
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
    
    private static let MonospaceFont: UIFont = {
        let bodyFont = UIFont.preferredFont(forTextStyle: .body)
        let size = bodyFont.pointSize
        return UIFont(name: "Menlo", size: size) ?? UIFont(name: "Courier", size: size) ?? bodyFont
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
    
    public var orderedListAttributes: TextAttributes? = [
        .font: fontWithTraits(traits: .traitBold, font:  UIFont.preferredFont(forTextStyle: .body))
    ]
    
    public var orderedListItemAttributes: TextAttributes? = [
        .font:UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.darkGray
    ]
    
    public var unorderedListAttributes: TextAttributes? = [
        .font: fontWithTraits(traits: .traitBold, font: UIFont.preferredFont(forTextStyle: .body)),
            .foregroundColor: UIColor.red
    ]
    
    public var unorderedListItemAttributes: TextAttributes? = [
        .font:  UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.darkGray
    ]
    
    public init() {}
}
