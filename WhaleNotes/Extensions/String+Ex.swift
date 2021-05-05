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
    
    var utf16Count:Int {
        return self.utf16.count
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
        if self.isEmpty { return nil }
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

extension String {
    func convertToTimeInterval() -> TimeInterval {
        guard self != "" else {
            return 0
        }

        var interval:Double = 0

        let parts = self.components(separatedBy: ":")
        for (index, part) in parts.reversed().enumerated() {
            interval += (Double(part) ?? 0) * pow(Double(60), Double(index))
        }

        return interval
    }
}

//MARK: 正则
extension String {
    
    func match(pattern:String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern,
                                                   options: .caseInsensitive) else { return false}
        let matches = regex.matches(in: self,
                    options: [],
                    range: NSMakeRange(0, self.utf16.count))
        return matches.count > 0
    }
    
    func rangeFirst(pattern:String) -> String? {
        if let range = self.range(of: pattern, options: .regularExpression) {
            let value = self[range]
            return String(value)
        }
        return nil
    }
}

//MARK: replace
extension String {
  
  public func replaceFirst(of pattern:String,
                           with replacement:String) -> String {
    if let range = self.range(of: pattern){
      return self.replacingCharacters(in: range, with: replacement)
    }else{
      return self
    }
  }
  
  public func replaceAll(of pattern:String,
                         with replacement:String,
                         options: NSRegularExpression.Options = []) -> String{
    do{
      let regex = try NSRegularExpression(pattern: pattern, options: [])
      let range = NSRange(0..<self.utf16.count)
      return regex.stringByReplacingMatches(in: self, options: [],
                                            range: range, withTemplate: replacement)
    }catch{
      NSLog("replaceAll error: \(error)")
      return self
    }
  }
  
}
extension String {
    func index(from: Int) -> Index {
        
        
//        let fromB2 = String.Index(utf16Offset: , in: self)
//        let toB2 = String.Index(utf16Offset: from, in: self)
//        
        return String.Index(utf16Offset: from, in: self)
//        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func subString(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }
    
    func subString(to: String.Index) -> String {
        return String(self[..<to])
    }


    func substring(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    static func getSymbolRange(text: String) ->Range<String.Index>?  {
        let matchRange = text.range(of: #"(?:(?:[*+-])[ ])"#,
                                       options: .regularExpression) //.utf16Offset(in: self)
        return matchRange
    }
    
    func range(of regex:String) -> NSRange? {
        guard let matchRange = self.range(of: regex,
                                          options: .regularExpression) else { return nil } //.utf16Offset(in: self)
        let loc =  matchRange.lowerBound.utf16Offset(in: self)
        let len =  matchRange.upperBound.utf16Offset(in: self)
        return NSMakeRange(loc, len)
    }
}


extension String {
    
    var isValidFileName: Bool {
        let pattern = "^[^\\.\\*\\:/]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        return predicate.evaluate(with: self)
    }
    
    static var unique: String {
        let time = Date().timeIntervalSince1970
        return time.toString
    }
    
    func firstMatch(_ exp: String) -> String? {
        guard let range = firstMatchRange(exp) else { return nil }
        return substring(with: range)
    }
    
    func firstMatchRange(_ exp: String) -> NSRange? {
        guard let exp = try? NSRegularExpression(pattern: exp, options: .anchorsMatchLines) else { return nil }
        
        guard let range = exp.firstMatch(in: self, options: .reportCompletion, range: NSRange(startIndex..., in: self))?.range else { return nil }
        if range.location == NSNotFound {
            return nil
        }
        return range
    }
    
    func matchsCount(_ exp: String) -> Int {
        guard let exp = try? NSRegularExpression(pattern: exp, options: .caseInsensitive) else { return 0 }
        return exp.matches(in: self, options: .reportCompletion, range: NSRange(startIndex..., in: self)).count
    }
    
    func substring(with nsRange: NSRange) -> String {
        let str = self as NSString
        return str.substring(with: nsRange)
    }
    
    func replacingCharacters(in nsRange: NSRange, with newString: String) -> String {
        let str = self as NSString
        return str.replacingCharacters(in: nsRange, with: newString)
    }
    
    
    func firstIntIndex(of member:String.Element) -> Int {
        return self.firstIndex(of: member)?.utf16Offset(in: self)  ?? -1
    }
    
    func lastIntIndex(of member:String.Element) -> Int {
        return self.lastIndex(of: member)?.utf16Offset(in: self)  ?? -1
    }
}
