//
//  MarkdownTextStorage.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/28/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

let ENTER_KEY:Character = "\n"
/**
*  Text storage with support for highlighting Markdown.
*/
public class MarkdownTextStorage: NSTextStorage {
    
    
//    let headerHightlighter = MDHeaderHighlighter(maxLevel: 3)
//
//    let tagHightlighter = MDTagHighlighter()
//    let linkHightlighter = MDLinkHighlighter()
//
//    let bulletHightlighter = MDBulletListHighlighter()
//    let numListHightlighter = MDNumListHighlighter()
    
//    private lazy var mdHighlighters:[MDHighlighterType] = [headerHightlighter,tagHightlighter,linkHightlighter]
    
    let highlightManager = MDHighlightManager()
    
    private  var backingStore:NSMutableAttributedString!
    var textView: UITextView!{
        didSet {
            
            let wholeRange = NSRange(location: 0, length: (self.string as NSString).length)
//            setAttributes(defaultAttributes, range: wholeRange)
            
            self.beginEditing()
            self.applyStylesToRange(searchRange: wholeRange)
            self.edited(.editedAttributes, range: wholeRange, changeInLength: 0)
            self.endEditing()
        }
    }
//    private var defaultAttributes: TextAttributes = MarkdownAttributes.mdDefaultAttributes
    var style:MDStyle!
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    convenience init(style:MDStyle) {
        self.init()
        self.style = style
        backingStore = NSMutableAttributedString(string: "", attributes: style.mdDefaultAttributes)
    }
    public override init() {
        super.init()
    }
    
    public override var string: String {
        return backingStore.string
    }
    
    public override func attributes(
      at location: Int,
      effectiveRange range: NSRangePointer?
    ) -> [NSAttributedString.Key: Any] {
      let attr = backingStore.attributes(at: location, effectiveRange: range)
     return attr
    }
    
    
    public override func replaceCharacters(in range: NSRange, with str: String) {
        print("replaceCharacters: \(str)")
      beginEditing()
      backingStore.replaceCharacters(in: range, with:str)
      edited(.editedCharacters, range: range,
             changeInLength: str.utf16Count - range.length)
      endEditing()
    }
      
    public override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
      guard range.upperBound <= string.utf16Count else { return }
      beginEditing()
      backingStore.setAttributes(attrs, range: range)
      edited(.editedAttributes, range: range, changeInLength: 0)
      endEditing()
    }
    
    public override func processEditing() {
        performReplacementsForRange(changedRange: editedRange)
        super.processEditing()
    }
    
    func performReplacementsForRange(changedRange: NSRange) {
        let lineRange = getCurrentLineRange(changedRange: changedRange)
        applyStylesToRange(searchRange: lineRange)
    }
    
    func applyStylesToRange(searchRange: NSRange) {
      setAttributes(style.mdDefaultAttributes, range: searchRange)
      highlightManager.highlight(textStorage: self, range: searchRange)
    }

    
    private func editedAll(actions: NSTextStorage.EditActions) {
        edited(actions, range: NSRange(location: 0, length: backingStore.length), changeInLength: 0)
    }
    
}

struct MarkdownHighlighter {
    var pattern:String
    var attributes:TextAttributes
}

extension MarkdownTextStorage {
    func replaceCharactersInRange(_ replaceRange: NSRange, withString str: String, selectedRangeLocationMove: Int) {
          if textView.undoManager!.isUndoing {
              textView.selectedRange = NSMakeRange(textView.selectedRange.location - selectedRangeLocationMove, 0)
              replaceCharactersInRange(NSMakeRange(replaceRange.location, str.utf16Count), withString: "")
          } else {
            replaceCharactersInRange(replaceRange, withString: str)
            textView.selectedRange = NSMakeRange(replaceRange.location + selectedRangeLocationMove, 0)
          }
      }
}



extension NSMutableAttributedString {

    func replaceCharactersInRange(_ range: NSRange, withString str: String) {
        if isSafeRange(range) {
            replaceCharacters(in: range, with: str)
        }
    }

    func isSafeRange(_ range: NSRange) -> Bool {
        if range.location < 0 {
            return false
        }
        let maxLength = range.location + range.length
        return maxLength <= string.utf16Count
    }
}

extension MarkdownTextStorage {
    private func tryGenerateNewLine(range: NSRange)  -> String {
        
        return ""
    }
    
}

extension MarkdownTextStorage {
    private func getCurrentLineRange(changedRange:NSRange) -> NSRange {
        let str = NSString(string: backingStore.string).lineRange(for: NSMakeRange(changedRange.location, 0))
        var extendedRange = NSUnionRange(changedRange,str)
        
        let str2 = NSString(string: backingStore.string).lineRange(for: NSMakeRange(NSMaxRange(changedRange), 0))
        extendedRange = NSUnionRange(changedRange,str2)
        return extendedRange
    }
}
