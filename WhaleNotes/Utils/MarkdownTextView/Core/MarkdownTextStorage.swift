//
//  MarkdownTextStorage.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/28/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

 let ENTER_KEY = "\n"
/**
*  Text storage with support for highlighting Markdown.
*/
public class MarkdownTextStorage: HighlighterTextStorage {
    private let attributes: MarkdownAttributes
    
    lazy var listHighlighter =  MarkdownListHighlighter(markerPattern: "[*+-]", attributes: attributes.unorderedListAttributes, itemAttributes: attributes.unorderedListItemAttributes)
    
    lazy var orderListHighlighter = MarkdownOrderListHighlighter(markerPattern: "\\d+[.]", attributes: attributes.orderedListAttributes, itemAttributes: attributes.orderedListItemAttributes)
    
    public override init() {
        self.attributes = MarkdownAttributes()
        super.init()
        commonInit()
        
        if let headerAttributes = attributes.headerAttributes {
            addHighlighter(highlighter: MarkdownHeaderHighlighter(attributes: headerAttributes))
        }
        addHighlighter(highlighter: listHighlighter)
        addHighlighter(highlighter: orderListHighlighter)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        attributes = MarkdownAttributes()
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        defaultAttributes = attributes.defaultAttributes
    }
    
}




//LIST OR ORDERLIST
extension MarkdownTextStorage {
    override func enterKetInput(range:NSRange,inputText:String,lineText: String, offset: Int) {
//        print("all string:\(string)")
        if listHighlighter.match(text: lineText) { // 输入的是list
            self.handleListInput(lineText: lineText,inputText:inputText, range: range, offset: offset)
            return
        }
        if orderListHighlighter.match(text: lineText) { // 输入的是 order list
//            self.handleOrderListInput(lineText: lineText,inputText:inputText, range: range, offset: offset)
//            print("all string------>:\(string)")
            self.orderListHighlighter.handleOrderListInput(textStorage: self, lineText: lineText, inputText: inputText, range: range, offset: offset)
            return
        }
    }
    
    
    private func handleListInput(lineText: String,inputText:String,range:NSRange, offset: Int) {
        let match = lineText.range(of: #"(?:[ ]{0,3}(?:[*+-])[ ])"#,
                                       options: .regularExpression)
        let isNumOnly = match == (lineText.startIndex..<lineText.endIndex)
        if isNumOnly {//最后一行,并且只有一个符号
            let replaceRange = NSMakeRange(range.location-lineText.count, lineText.count+1)
            replaceCharactersInRange(replaceRange, withString: "", selectedRangeLocationMove: -1)
            return
        }
        
        let matchRange = lineText.range(of: #"(?:(?:[*+-])[ ])"#,
                                       options: .regularExpression)! //.utf16Offset(in: self)
        let index =  matchRange.lowerBound.utf16Offset(in: lineText)
        let extraSpace = lineText.substring(to:index )
        
        let prefix = lineText.substring(with:(index..<(index+2)))
        let newText = "\n"+extraSpace+prefix
        let newRange = NSMakeRange(range.location, 1)
        replaceCharactersInRange(newRange, withString: newText,selectedRangeLocationMove: newText.count-1)
    }
    

}




extension MarkdownTextStorage {
    
}




extension MarkdownTextStorage {
    func replaceCharactersInRange(_ replaceRange: NSRange, withString str: String, selectedRangeLocationMove: Int) {
          if textView.undoManager!.isUndoing {
              textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
              replaceCharactersInRange(NSMakeRange(replaceRange.location, str.count), withString: "")
          } else {
            replaceCharactersInRange(replaceRange, withString: str)
            textView.selectedRange = NSMakeRange(replaceRange.location + selectedRangeLocationMove, 0)
          }
      }
}


