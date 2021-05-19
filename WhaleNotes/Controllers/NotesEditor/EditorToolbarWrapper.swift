//
//  EditorToolbarWrapper.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/5/16.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

class EditorToolbarWrapper: NSObject {
    
    var textStorage:MarkdownTextStorage!
    
    var highlightManager:MDHighlightManager {
        return textStorage.highlightManager
    }
    
    weak var textView:UITextView?
    var text:String {
        return textView?.text ?? ""
    }
    private var tempTime:Int64  = 0
    var editorDelegate:MarkdownTextViewDelegate?
    var textviewTappedDelegate:MDTextViewTappedDelegate?
    
    var selectedRange:NSRange {
        get { return self.textView?.selectedRange ?? NSMakeRange(0, 0)
        }
        set {
            self.textView?.selectedRange = newValue
        }
    }
    
    
    init(textView: UITextView,isEditable:Bool  = false) {
        super.init()
        self.textView = textView
        self.textStorage = (textView.textStorage as! MarkdownTextStorage)
        
    }
    
    func insertText(_ text:String) {
        self.textView?.insertText(text)
    }
}

extension EditorToolbarWrapper:MDKeyboarActionDelegate {
    func listButtonTapped() {
        self.changeCurrentLine2List()
    }
    
    func orderListButtonTapped() {
        
    }
    
    func keyboardButtonTapped() {
        self.textView?.resignFirstResponder()
    }
    
    
    func changeCurrentLine2List() {
      
    }
}
