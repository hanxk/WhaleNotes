//
//  TextUtils.swift
//  MarkdownTextView
//
//  Created by hanxk on 2020/12/26.
//  Copyright © 2020 Indragie Karunaratne. All rights reserved.
//

import Foundation

class TextUtils {
    class func isReturn(str: String) -> Bool {
        return str == "\n"
    }

    class func isBackspace(str: String) -> Bool {
        return str == ""
    }
    
    class func getLineRange(_ string: String, location: Int) -> Range<Int> {
//        var end = location
        
        let start = string.substring(to: location).lastIntIndex(of: "\n") + 1
        
        let endStr  = string.substring(from: location)
        var end = endStr.firstIntIndex(of: "\n")
        if end ==  -1 {
            end = string.utf16Count
        }else {
            end = string.utf16Count - endStr.utf16Count +  end
        }
//        if end > string.count {
//            end = string.count
//        }
        return (start..<end)
    }
    

    class func startOffset(_ string: String, location: Int) -> (String, Int) {
        
        let lineRange  = TextUtils.getLineRange(string, location: location)
        let lineText = string.substring(with: lineRange)
        
//        var lineText = string.substring(to: location)
//        if lineText.contains("\n") {
//            lineText = lineText.substring(from: lineText.lastIndex(of: "\n")!)
//        }
//        let offset = location
//        var offset: Int = 0
//        var word = NSString(string: string).substring(to: location)
//        let lines = string.components(separatedBy: "\n")
//
//        if lines.count > 0 {
//            let last = lines.last!
//
//            offset = abs(word.count - last.count)
//            word = last
//        }
//
        print("lineText:\(lineText) location:\(location) ")
        return (lineText, location)
    }
    
    
}
