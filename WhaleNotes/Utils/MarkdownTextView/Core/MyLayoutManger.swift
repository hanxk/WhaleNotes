//
//  MyLayoutManger.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/31.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

let  lineHeightMultiple:CGFloat = 1.5

let font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)

let defaultLineHeight = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body).lineHeight

class MyLayoutManger: NSLayoutManager {
    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
//        print("光标：\(origin.y)")
//        let y = (24 - UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body).pointSize)  / 2
//        print("y-------->\(y)")
        print(glyphsToShow)
        var newOrigin = origin
//        newOrigin.y  = 0
//        let font =  UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
//        font.pointSize - font.descender
//        CGFloat ascent = CTFontGetAscent(theFont);
//        CGFloat descent = CTFontGetDescent(theFont);
//        CGFloat leading = CTFontGetLeading(theFont);
        
//        let a = ((lineHeightMultiple - 1) * defaultLineHeight - font.descender) / (3   - lineHeightMultiple)
//        let a = ((lineHeightMultiple - 1）* defaultLineHeight - font.descender）/（3 - lineHeightMultiple）
//        print("哈哈哈哈哈哈 \(a)")
        
        super.drawGlyphs(forGlyphRange:  glyphsToShow, at: newOrigin)
    }
    
//    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>,
//                                          count rectCount: Int,
//                                          forCharacterRange charRange: NSRange,
//                                          color: UIColor) {
//
//        self.enumerateLineFragments(forGlyphRange: charRange) { (rect, usedRect, textContainer, glyphRange, stop) in
//
//            var newRect = rectArray[0]
//            newRect.origin.y = usedRect.origin.y + (usedRect.size.height / 4.0)
//            newRect.size.height = usedRect.size.height / 2.0
//
//            let currentContext = UIGraphicsGetCurrentContext()
//            currentContext?.saveGState()
//            currentContext?.setFillColor(UIColor.blue.cgColor)
//            currentContext?.fill(newRect)
//
//            currentContext?.restoreGState()
//        }
//    }
    
    
}
