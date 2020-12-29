//
//  MarkdownTextView.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/29/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

/**
*  Text view with support for highlighting Markdown syntax.
*/
public class MarkdownTextView: UITextView {
    /**
    Creates a new instance of the receiver.
    
    :param: frame       The view frame.
    :param: textStorage The text storage. This can be customized by the
    caller to customize text attributes and add additional highlighters
    if the defaults are not suitable.
    
    :returns: An initialized instance of the receiver.
    */
    
    var mdTextStorage:MarkdownTextStorage!
    
    public init(frame: CGRect, textStorage: MarkdownTextStorage = MarkdownTextStorage()) {
        let textContainer = NSTextContainer()
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        super.init(frame: frame, textContainer: textContainer)
        textStorage.textView = self
        self.delegate = self
        self.mdTextStorage = textStorage
        
        let keyboardView = MDKeyboardView()
        keyboardView.delegate = self
        
        self.inputAccessoryView = keyboardView
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MarkdownTextView:UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            print("哈哈哈")
            return true
        }
        return true
    }
    
    private func handleEnterKeyEvent(textView: UITextView) -> Bool {
//        let lineStr = textView.getLineString()
        
        // 是否是 list,如果是empty，删除当前行，否则：新加一行
        
        
        return true
    }
}


extension UITextView {
    func getLineString() -> String {
        return (self.text! as NSString).substring(with: (self.text! as NSString).lineRange(for: self.selectedRange))
    }

}


extension MarkdownTextView:MDKeyboarActionDelegate {
    func listButtonTapped() {
        self.changeCurrentLine2List()
    }
    
    func orderListButtonTapped() {
        self.changeCurrentLine2OrderList()
    }
    
    func keyboardButtonTapped() {
        self.resignFirstResponder()
    }
    
    
    func changeCurrentLine2List() {
        let locaction = self.selectedRange.location
        let lineRange = TextUtils.getLineRange(self.text, location: locaction)
        let lineText = self.text.substring(with: lineRange)
        if let symbolRange = self.mdTextStorage.listHighlighter.getSymbolNSRange(text: lineText) {
            let move = 2
            let sympolL = lineRange.lowerBound + symbolRange.location
            self.mdTextStorage.replaceCharactersInRange(NSMakeRange(sympolL, 2), withString: "", selectedRangeLocationMove: move)
            return
        }
        let move = lineText.count + 2
        self.mdTextStorage.replaceCharactersInRange(NSMakeRange(lineRange.lowerBound, 0), withString: "- ", selectedRangeLocationMove: move)
        
    }
    
    
    
}

extension MarkdownTextView {
    
    func changeCurrentLine2OrderList() {
        let locaction = self.selectedRange.location
        let lineRange = TextUtils.getLineRange(self.text, location: locaction)
        let lineText = self.text.substring(with: lineRange)
        
        if let symbolRange = self.mdTextStorage.orderListHighlighter.getSymbolNSRange(text: lineText) {//移除num
//            let move = lineText.count - 3
            
            let move = locaction - lineRange.lowerBound - 3
            
            let sympolL = lineRange.lowerBound + symbolRange.location
            self.mdTextStorage.replaceCharactersInRange(NSMakeRange(sympolL, 3), withString: "", selectedRangeLocationMove: move)
            
            //更新其它行
            self.mdTextStorage.orderListHighlighter.tryUpdateOtherOrderList(textStorage: self.mdTextStorage, cursorPos: locaction-move, numBegin: 1)
            
            return
        }
        
        self.updateLine2NumListItem(location: locaction)
        
//        let sympolL = lastLineRange.lowerBound + symbolRange.location
//        self.mdTextStorage.replaceCharactersInRange(NSMakeRange(sympolL, 3), withString: "", selectedRangeLocationMove: move)
        
        
//        let move = lineText.count + 2
//        self.mdTextStorage.replaceCharactersInRange(NSMakeRange(0, 0), withString: "- ", selectedRangeLocationMove: move)

    }
    
    func updateLine2NumListItem(location:Int) {
        let lineRange = TextUtils.getLineRange(self.text, location: location)
        let lineText = self.text.substring(with: lineRange)
        
        var num = 1
        
        // 获取上一行的symbol num
        if lineRange.lowerBound  > 0 {
            let lastLineRange = TextUtils.getLineRange(self.text, location: lineRange.lowerBound-1)
            let lastLineText = self.text.substring(with: lastLineRange)
            
            if let lastSymbolRange = self.mdTextStorage.orderListHighlighter.getSymbolNSRange(text: lastLineText)  {
                let sympolL = lastSymbolRange.location
                let numStr = NSString(string: lastLineText.substring(with: (sympolL..<1)))
    //            if numStr != nil {
    //
    //            }
                num = numStr.integerValue + 1
            }
        }
        
        let symbolS = "\(num). "
        let move = location - lineRange.lowerBound + symbolS.count
        let sympolL = lineRange.lowerBound
        self.mdTextStorage.replaceCharactersInRange(NSMakeRange(sympolL, 0), withString: symbolS, selectedRangeLocationMove: move)
        
        
        self.mdTextStorage.orderListHighlighter.tryUpdateOtherOrderList(textStorage: self.mdTextStorage, cursorPos: location+symbolS.count, numBegin: num+1)
        
    }
}
