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
    let fontName  = "Avenir Next"
    
    init(fontSize:CGFloat,lineHeightMultiple: CGFloat = 1.2) {
        self.font = UIFont(name:fontName,size: fontSize)!
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
