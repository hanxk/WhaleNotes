//
//  MDStyle.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/9.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

struct MDStyle {
    let mdDefaultAttributes:TextAttributes
    var font: UIFont
    
    init(fontSize:CGFloat,lineHeightMultiple: CGFloat = 1.2) {
        self.font = MDStyle.generateDefaultFont(fontSize: fontSize)
        let paragraphStyle = { () -> NSMutableParagraphStyle in
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineHeightMultiple = lineHeightMultiple
            return paraStyle
        }()
        self.mdDefaultAttributes =  [
            .font: font,
            .foregroundColor: UIColor.primaryText,
            .paragraphStyle: paragraphStyle
        ]
    }
}

extension MDStyle {
    static func generateDefaultFont(fontSize: CGFloat,weight:UIFont.Weight = .regular) -> UIFont {
        var fontName  = "Avenir Next"
        if weight == .medium {
            fontName = "AvenirNext-Medium"
        }
        return UIFont(name:fontName,size: fontSize) ?? UIFont.systemFont(ofSize: fontSize,weight: weight)
    }
}

extension UIFont {
  func withWeight(_ weight: UIFont.Weight) -> UIFont {
    let newDescriptor = fontDescriptor.addingAttributes([.traits: [
      UIFontDescriptor.TraitKey.weight: weight]
    ])
    return UIFont(descriptor: newDescriptor, size: pointSize)
  }
}
