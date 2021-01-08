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


protocol LayoutManagerDelegate: AnyObject {
    var typingAttributes: [NSAttributedString.Key: Any] { get }
    var selectedRange: NSRange { get }
    var paragraphStyle: NSMutableParagraphStyle? { get }
    var font: UIFont? { get }
    var textColor: UIColor? { get }
    var textContainerInset: UIEdgeInsets { get }
    
    //    var listLineFormatting: LineFormatting { get }
    
    //    func listMarkerForItem(at index: Int, level: Int, previousLevel: Int, attributeValue: Any?) -> ListLineMarker
}


public extension NSAttributedString.Key {
    static let backgroundStyle = NSAttributedString.Key("_backgroundStyle")
    static let tagStyle = NSAttributedString.Key("_tagStyle")
}

class MyLayoutManger: NSLayoutManager {
    weak var layoutManagerDelegate: LayoutManagerDelegate?
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
    
//    override func showCGGlyphs(_ glyphs: UnsafePointer<CGGlyph>, positions: UnsafePointer<CGPoint>, count glyphCount: Int, font: UIFont, textMatrix: CGAffineTransform, attributes: [NSAttributedString.Key : Any] = [:], in CGContext: CGContext) {
//        <#code#>
//    }
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        guard let textStorage = textStorage,
              let currentCGContext = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage.enumerateAttribute(.tagStyle, in: characterRange) { attr, bgStyleRange, _ in
            var rects = [CGRect]()
            if let tagStyle = attr as? TagStyle {
                let tagStyleGlyphRange = self.glyphRange(forCharacterRange: bgStyleRange, actualCharacterRange: nil)
                enumerateLineFragments(forGlyphRange: tagStyleGlyphRange) { _, usedRect, textContainer, lineRange, _ in
                    let rangeIntersection = NSIntersectionRange(tagStyleGlyphRange, lineRange)
                    var rect = self.boundingRect(forGlyphRange: rangeIntersection, in: textContainer)
                    // Glyphs can take space outside of the line fragment, and we cannot draw outside of it.
                    // So it is best to restrict the height just to the line fragment.
                    rect.origin.y = usedRect.origin.y
                    rect.size.height = usedRect.height
                    let insetTop = self.layoutManagerDelegate?.textContainerInset.top ?? 0
                    rects.append(rect.offsetBy(dx: 0, dy: insetTop))
                }
                drawBackground(tagStyle: tagStyle, rects: rects, currentCGContext: currentCGContext)
            }
        }
    }
    private func drawBackground(tagStyle: TagStyle, rects: [CGRect], currentCGContext: CGContext) {
        currentCGContext.saveGState()
        
        let rectCount = rects.count
        let rectArray = rects
        let cornerRadius = tagStyle.cornerRadius
        let color = tagStyle.background
        
        for i in 0..<rectCount {
            var previousRect = CGRect.zero
            var nextRect = CGRect.zero
            
            let currentRect = rectArray[i]
            
            if i > 0 {
                previousRect = rectArray[i - 1]
            }
            
            if i < rectCount - 1 {
                nextRect = rectArray[i + 1]
            }
            
            let corners = calculateCornersForBackground(previousRect: previousRect, currentRect: currentRect, nextRect: nextRect, cornerRadius: cornerRadius)
            
            let rectanglePath = UIBezierPath(roundedRect: currentRect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
            color.set()
            
            currentCGContext.setAllowsAntialiasing(true)
            currentCGContext.setShouldAntialias(true)
            
//            if let shadowStyle = backgroundStyle.shadow {
//                currentCGContext.setShadow(offset: shadowStyle.offset, blur: shadowStyle.blur, color: shadowStyle.color.cgColor)
//            }
            
            currentCGContext.setFillColor(color.cgColor)
            currentCGContext.addPath(rectanglePath.cgPath)
            currentCGContext.drawPath(using: .fill)
            
//            let lineWidth = backgroundStyle.border?.lineWidth ?? 0
            let lineWidth:CGFloat =  0
            let overlappingLine = UIBezierPath()
            
            // TODO: Revisit shadow drawing logic to simplify a bit
            let leftVerticalJoiningLine = UIBezierPath()
            let rightVerticalJoiningLine = UIBezierPath()
            // Shadow for vertical lines need to be drawn separately to get the perfect alignment with shadow on rectangles.
            let leftVerticalJoiningLineShadow = UIBezierPath()
            let rightVerticalJoiningLineShadow = UIBezierPath()
            
            if previousRect != .zero, (currentRect.maxX - previousRect.minX) > cornerRadius {
                let yDiff = currentRect.minY - previousRect.maxY
                overlappingLine.move(to: CGPoint(x: max(previousRect.minX, currentRect.minX) + lineWidth/2, y: previousRect.maxY + yDiff/2))
                overlappingLine.addLine(to: CGPoint(x: min(previousRect.maxX, currentRect.maxX) - lineWidth/2, y: previousRect.maxY + yDiff/2))
                
                let leftX = max(previousRect.minX, currentRect.minX)
                let rightX = min(previousRect.maxX, currentRect.maxX)
                
                leftVerticalJoiningLine.move(to: CGPoint(x: leftX, y: previousRect.maxY))
                leftVerticalJoiningLine.addLine(to: CGPoint(x: leftX, y: currentRect.minY))
                
                rightVerticalJoiningLine.move(to: CGPoint(x: rightX, y: previousRect.maxY))
                rightVerticalJoiningLine.addLine(to: CGPoint(x: rightX, y: currentRect.minY))
                
                let leftShadowX = max(previousRect.minX, currentRect.minX) + lineWidth
                let rightShadowX = min(previousRect.maxX, currentRect.maxX) - lineWidth
                
                leftVerticalJoiningLineShadow.move(to: CGPoint(x: leftShadowX, y: previousRect.maxY))
                leftVerticalJoiningLineShadow.addLine(to: CGPoint(x: leftShadowX, y: currentRect.minY))
                
                rightVerticalJoiningLineShadow.move(to: CGPoint(x: rightShadowX, y: previousRect.maxY))
                rightVerticalJoiningLineShadow.addLine(to: CGPoint(x: rightShadowX, y: currentRect.minY))
            }
            
//            if let borderColor = backgroundStyle.border?.color {
//                currentCGContext.setLineWidth(lineWidth * 2)
//                currentCGContext.setStrokeColor(borderColor.cgColor)
//
//                // always draw vertical joining lines
//                currentCGContext.addPath(leftVerticalJoiningLineShadow.cgPath)
//                currentCGContext.addPath(rightVerticalJoiningLineShadow.cgPath)
//
//                currentCGContext.drawPath(using: .stroke)
//            }
            
            currentCGContext.setShadow(offset: .zero, blur:0, color: UIColor.clear.cgColor)
            
//            if let borderColor = backgroundStyle.border?.color {
//                currentCGContext.setLineWidth(lineWidth)
//                currentCGContext.setStrokeColor(borderColor.cgColor)
//                currentCGContext.addPath(rectanglePath.cgPath)
//
//                // always draw vertical joining lines
//                currentCGContext.addPath(leftVerticalJoiningLine.cgPath)
//                currentCGContext.addPath(rightVerticalJoiningLine.cgPath)
//
//                currentCGContext.drawPath(using: .stroke)
//            }
            
            // always draw over the overlapping bounds of previous and next rect to hide shadow/borders
            currentCGContext.setStrokeColor(color.cgColor)
            currentCGContext.addPath(overlappingLine.cgPath)
            // account for the spread of shadow
//            let blur = (backgroundStyle.shadow?.blur ?? 1) * 2
//            let offsetHeight = abs(backgroundStyle.shadow?.offset.height ?? 1)
            let blur:CGFloat =  2
            let offsetHeight:CGFloat = 1
            currentCGContext.setLineWidth(lineWidth + (currentRect.minY - previousRect.maxY) + blur + offsetHeight + 1)
            currentCGContext.drawPath(using: .stroke)
        }
        currentCGContext.restoreGState()
    }
    
//    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
//        guard let textStorage = textStorage,
//              let currentCGContext = UIGraphicsGetCurrentContext(),
//              let backgroundStyle = textStorage.attribute(.backgroundStyle, at: charRange.location, effectiveRange: nil) as? BackgroundStyle else {
//            super.fillBackgroundRectArray(rectArray, count: rectCount, forCharacterRange: charRange, color: color)
//            return
//        }
//
//        currentCGContext.saveGState()
//        let cornerRadius = backgroundStyle.cornerRadius
//
//        let corners = UIRectCorner.allCorners
//
//        for i in 0..<rectCount  {
//            let rect = rectArray[i]
//            let rectanglePath = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
//            color.set()
//
//            if let shadowStyle = backgroundStyle.shadow {
//                currentCGContext.setShadow(offset: shadowStyle.offset, blur: shadowStyle.blur, color: shadowStyle.color.cgColor)
//            }
//
//            currentCGContext.setAllowsAntialiasing(true)
//            currentCGContext.setShouldAntialias(true)
//
//            currentCGContext.setFillColor(color.cgColor)
//            currentCGContext.addPath(rectanglePath.cgPath)
//            currentCGContext.drawPath(using: .fill)
//        }
//        currentCGContext.restoreGState()
//    }
}

extension MyLayoutManger {
    private func calculateCornersForBackground(previousRect: CGRect, currentRect: CGRect, nextRect: CGRect, cornerRadius: CGFloat) -> UIRectCorner {
        var corners = UIRectCorner()
        
        if previousRect.minX > currentRect.minX {
            corners.formUnion(.topLeft)
        }
        
        if previousRect.maxX < currentRect.maxX {
            corners.formUnion(.topRight)
        }
        
        if currentRect.maxX > nextRect.maxX {
            corners.formUnion(.bottomRight)
        }
        
        if currentRect.minX < nextRect.minX {
            corners.formUnion(.bottomLeft)
        }
        
        if nextRect == .zero || nextRect.maxX <= currentRect.minX + cornerRadius {
            corners.formUnion(.bottomLeft)
            corners.formUnion(.bottomRight)
        }
        
        if previousRect == .zero || (currentRect.maxX <= previousRect.minX + cornerRadius) {
            corners.formUnion(.topLeft)
            corners.formUnion(.topRight)
        }
        
        return corners
    }
    
    private func getCornersForBackground(textStorage: NSTextStorage, for charRange: NSRange) -> UIRectCorner {
        let isFirst = (charRange.location == 0)
            || (textStorage.attribute(.backgroundStyle, at: charRange.location - 1, effectiveRange: nil) == nil)
        
        let isLast = (charRange.upperBound == textStorage.length) ||
            (textStorage.attribute(.backgroundStyle, at: charRange.location + charRange.length, effectiveRange: nil) == nil)
        
        var corners = UIRectCorner()
        if isFirst {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
        }
        
        if isLast {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
        }
        
        return corners
    }
}
