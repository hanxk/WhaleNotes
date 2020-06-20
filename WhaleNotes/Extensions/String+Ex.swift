//
//  String+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

extension String {
    func height(withWidth width: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [.font : font], context: nil)
        return actualSize.height
    }
    
    func width(withHeight height: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [.font : font], context: nil)
        return actualSize.width
    }
    
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
    var isWhiteHex: Bool {
        return  self.lowercased() == "#ffffff"
    }
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}


extension String{
    
    //MARK:获得string内容高度
    
    func stringHeightWith(fontSize:CGFloat,width:CGFloat,lineSpace: CGFloat = -1)->CGFloat{
        let font = UIFont.systemFont(ofSize: fontSize)
        let size = CGSize(width: width, height: CGFloat(MAXFLOAT))
        let paragraphStyle = NSMutableParagraphStyle()
        if lineSpace == -1 {
            paragraphStyle.lineSpacing = lineSpace
        }
        paragraphStyle.lineBreakMode = .byWordWrapping;
        let attributes = [NSAttributedString.Key.font:font, NSAttributedString.Key.paragraphStyle:paragraphStyle.copy()]
        let text = self as NSString
        let rect = text.boundingRect(with: size, options:.usesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.height
    }
    
    func stringHeightWith(width:CGFloat,style: NSMutableParagraphStyle)->CGFloat{
        let attributes = [NSAttributedString.Key.paragraphStyle:style.copy()]
        let size = CGSize(width: width, height: CGFloat(MAXFLOAT))
        let text = self as NSString
        let rect = text.boundingRect(with: size, options:.usesLineFragmentOrigin, attributes: attributes, context:nil)
        return rect.size.height
    }
}


extension String {
    
    func convertToDictionary() -> [String: Any] {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]
            } catch {
                print(error.localizedDescription)
            }
        }
        return [:]
    }
    func emojiToImage(size:CGSize,fontSize:CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.white.set()
        let rect = CGRect(origin: CGPoint(), size: size)
        UIRectFill(rect)
        (self as NSString).draw(in: rect, withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func emojiToImage(fontSize:CGFloat) -> UIImage? {
           let nsString = (self as NSString)
           let font = UIFont.systemFont(ofSize: fontSize) // you can change your font size here
           let stringAttributes = [NSAttributedString.Key.font: font]
           let imageSize = nsString.size(withAttributes: stringAttributes)

           UIGraphicsBeginImageContextWithOptions(imageSize, false, 0) //  begin image context
           UIColor.clear.set() // clear background
           UIRectFill(CGRect(origin: CGPoint(), size: imageSize)) // set rect size
           nsString.draw(at: CGPoint.zero, withAttributes: stringAttributes) // draw text within rect
           let image = UIGraphicsGetImageFromCurrentImageContext() // create image from context
           UIGraphicsEndImageContext() //  end image context

           return image ?? UIImage()
    }
}

extension NSAttributedString {

    func height(containerWidth: CGFloat) -> CGFloat {

        let rect = self.boundingRect(with: CGSize.init(width: containerWidth, height: CGFloat.greatestFiniteMagnitude),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.height)
    }

    func width(containerHeight: CGFloat) -> CGFloat {

        let rect = self.boundingRect(with: CGSize.init(width: CGFloat.greatestFiniteMagnitude, height: containerHeight),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading],
                                     context: nil)
        return ceil(rect.size.width)
    }
}
