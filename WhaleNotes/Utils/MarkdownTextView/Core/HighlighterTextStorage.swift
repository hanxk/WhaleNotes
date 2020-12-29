//
//  RegularExpressionTextStorage.swift
//  MarkdownTextView
//
//  Created by Indragie on 4/28/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import UIKit

/**
 *  Text storage with support for automatically highlighting text
 *  as it changes.
 */
public class HighlighterTextStorage: NSTextStorage {
    private let backingStore: NSMutableAttributedString
    private var highlighters = [HighlighterType]()
    var textView: UITextView!
    /// Default attributes to use for styling text.
    public var defaultAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .body)
    ] {
        didSet { editedAll(actions: .editedAttributes) }
    }
    
    // MARK: API
    
    /**
     Adds a highlighter to use for highlighting text.
     
     Highlighters are invoked in the order in which they are added.
     
     :param: highlighter The highlighter to add.
     */
    public func addHighlighter(highlighter: HighlighterType) {
        highlighters.append(highlighter)
        editedAll(actions: .editedAttributes)
    }
    
    // MARK: Initialization
    
    public override init() {
        backingStore = NSMutableAttributedString(string: "", attributes: defaultAttributes)
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        backingStore = NSMutableAttributedString(string: "", attributes: defaultAttributes)
        super.init(coder: aDecoder)
    }
    
    // MARK: NSTextStorage
    
    public override var string: String {
        return backingStore.string
    }
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return backingStore.attributes(at: location, effectiveRange: range)
    }
    
    //    public override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
    ////        backingStore.replaceCharacters(in: range, with: attrString)
    ////        edited(.editedCharacters, range: range, changeInLength: attrString.length - range.length)
    //    }
    
    public override func replaceCharacters(in range: NSRange, with str: String) {
        var lineOffset = 0
        var lineText = ""
        if (TextUtils.isReturn(str: str)) {
            let line = TextUtils.startOffset(self.string, location: range.location)
            lineText = line.0
            lineOffset = line.1
        }
        beginEditing()
        backingStore.replaceCharacters(in: range, with:str)
        edited(.editedCharacters, range: range,changeInLength: (str as NSString).length - range.length)
        endEditing()
        if TextUtils.isReturn(str: str) {
            self.enterKetInput(range: range,inputText:str, lineText: lineText, offset: lineOffset)
        }
        
    }
    
    //    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
    //        backingStore.setAttributes(attrs, range: range)
    //        edited(.editedAttributes, range: range, changeInLength: 0)
    //    }
    public override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
//        print("setAttributes:\(String(describing: attrs)) range:\(range)")
        guard range.upperBound <= string.count else { return }
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
        highlightRange(range: lineRange)
    }
    
    
    
    private func editedAll(actions: NSTextStorage.EditActions) {
        edited(actions, range: NSRange(location: 0, length: backingStore.length), changeInLength: 0)
    }
    
    private func highlightRange(range: NSRange) {
        backingStore.beginEditing()
        setAttributes(defaultAttributes, range: range)
        let attrString = backingStore.attributedSubstring(from: range).mutableCopy() as! NSMutableAttributedString
        for highlighter in highlighters {
            highlighter.highlightAttributedString(attributedString: attrString)
        }
        replaceCharacters(in: range, with: attrString)
        backingStore.endEditing()
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
        return maxLength <= string.count
    }
}

extension HighlighterTextStorage {
    private func tryGenerateNewLine(range: NSRange)  -> String {
        
        return ""
    }
    
}

extension HighlighterTextStorage {
    private func getCurrentLineRange(changedRange:NSRange) -> NSRange {
        let str = NSString(string: backingStore.string).lineRange(for: NSMakeRange(changedRange.location, 0))
        var extendedRange = NSUnionRange(changedRange,str)
        
        let str2 = NSString(string: backingStore.string).lineRange(for: NSMakeRange(NSMaxRange(changedRange), 0))
        extendedRange = NSUnionRange(changedRange,str2)
        return extendedRange
    }
}


extension HighlighterTextStorage {
    
    // 处理回车键
    @objc func enterKetInput(range: NSRange,inputText:String, lineText:String,offset:Int) {
        // 是否是 list
    }
    
}
