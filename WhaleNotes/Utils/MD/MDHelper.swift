//  MDHelper.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/23.
//  Copyright © 2020 hanxk. All rights reserved.
//  Created by hanxk on 2021/7/11.
//  Copyright © 2021 hanxk. All rights reserved.
//
import RxSwift
import UIKit

class MDHelper:NSObject   {
    
//    let markdownRenderer = MarkdownRender.shared()
    var highlightmanager = MDSyntaxHighlighter()
    let bag = DisposeBag()
    
    var shouldRender = false
    
    var timer: Timer?
    var editView: UITextView!
//    let editView: TextView = TextView().then {
//        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
//        $0.textColor = .primaryText
//        $0.isEditable = true
//        $0.keyboardDismissMode = .onDrag
//        $0.alwaysBounceVertical = true
//        $0.textContainer.lineBreakMode = .byCharWrapping
//    }
    
    init(editView:UITextView) {
        super.init()
        self.editView = editView
        self.highlight()
    }
    
    var text:String{
        set {
            self.editView.text  =  newValue
        }
        get {
            return self.editView.text
        }
    }
    
    var visibleRange: NSRange? {
        let topLeft = CGPoint(x: editView.bounds.minX, y: editView.bounds.minY)
        let bottomRight = CGPoint(x: editView.bounds.maxX, y: editView.bounds.maxY)
        guard let topLeftTextPosition = editView.closestPosition(to: topLeft),
            let bottomRightTextPosition = editView.closestPosition(to: bottomRight) else {
                return nil
        }
        let location = editView.offset(from: editView.beginningOfDocument, to: topLeftTextPosition)
        let length = editView.offset(from: topLeftTextPosition, to: bottomRightTextPosition)
        return NSRange(location: location, length: length)
    }
    
    var isRendering = false {
        didSet {
//            if isRendering {
//                DispatchQueue.global().async { [weak self] in
//                    let html = self?.markdownRenderer?.renderMarkdown(self?.editView.text) ?? ""
//                    DispatchQueue.main.async {
////                        self?.previewVC.html = html
//                        self?.isRendering = false
//                    }
//                }
//                shouldRender = false
//            } else {
//                if shouldRender {
//                    DispatchQueue.main.async {
//                        self.isRendering = true
//                    }
//                }
//            }
        }
    }
    
    
    
    func render() {
        if isRendering == false {
            isRendering = true
        } else {
            shouldRender = true
        }
    }
    
    func loadText(_ text: String) {
        self.text = text
        if text.count == 0 {
            editView.becomeFirstResponder()
            return
        }
        if text.length > 800 {
            editView.text = text[0..<800]
//            ActivityIndicator.show(on: self.editView)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                guard let this = self else { return }
                this.editView.text = text
                this.textViewDidChange(this.editView)
//                ActivityIndicator.dismissOnView(this.editView)
            }
        } else {
            editView.text = text
            textViewDidChange(editView)
        }
    }
    
    deinit {
        timer?.invalidate()
//        removeNotificationObserver()
        print("deinit text_vc")
    }
}

extension MDHelper: UITextViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.isDragging {
//            let offset = scrollView.contentOffset.y
//            if contentHeight - scrollView.h > 0 {
//                didScrollHandler?(offset / (contentHeight - scrollView.h))
//            }
//        }
//        if Configure.shared.autoHideNavigationBar.value == false {
//            return
//        }
//        let pan = scrollView.panGestureRecognizer
//        let velocity = pan.velocity(in: scrollView).y
//        if velocity < -600 {
//            self.navigationController?.setNavigationBarHidden(true, animated: true)
//        } else if velocity > 600 {
//            self.navigationController?.setNavigationBarHidden(false, animated: true)
//        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        if editView.text.count < 5000 {
//            return
//        }
//        if fabs(scrollView.contentOffset.y - lastOffsetY) < 500 {
//            return
//        }
//        timer?.invalidate()
//        let contentOffset = editView.contentOffset
//        highlight()
//        editView.contentOffset = contentOffset
//        lastOffsetY = scrollView.contentOffset.y
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIApplication.shared.isIdleTimerDisabled = true
//        if Configure.shared.autoHideNavigationBar.value {
//            navigationController?.setNavigationBarHidden(true, animated: true)
//        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIApplication.shared.isIdleTimerDisabled = false
//        navigationController?.setNavigationBarHidden(false, animated: true)
//        textEndEditing?(textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let begin = max(range.location - 100, 0)
            let len = range.location - begin
            let nsString = textView.text! as NSString
            let nearText = nsString.substring(with: NSRange(location:begin, length: len))
            let texts = nearText.components(separatedBy: "\n")
//            if texts.count < 2 {
//                return true
//            }
            
//            let lastLineCount = texts.last!.count   // emoji bug
            let lastLineCount = texts.last!.utf16.count
            let beginning = textView.beginningOfDocument
            guard let from = textView.position(from: beginning, offset: range.location - lastLineCount),
                let to = textView.position(from: beginning, offset: range.location),
                let textRange = textView.textRange(from: from, to: to) else {
                return true
            }
            let newText  =  newLine(texts.last!)
            textView.replace(textRange, withText: newText)
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
//        placeholderLabel.isHidden = !text.isEmpty
//        if editView.markedTextRange != nil {
//            return
//        }
//        textChangedHandler?(text)
//
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(highlight), userInfo: nil, repeats: false)
//        _textWidth = 0
    }
    
}


extension MDHelper {
    @objc func highlight() {
        if editView.text.count < 5000 {
//            highlightmanager.highlight(editView.textStorage,visibleRange: nil)
        } else if let range = self.visibleRange {
            highlightmanager.highlight(editView.textStorage,visibleRange: range)
        }
        
    }
    
    func newLine(_ last: String) -> String {
        if last.hasPrefix("- [x] ") {
            return last + "\n- [x] "
        }
        if last.hasPrefix("- [ ] ") {
            return last + "\n- [ ] "
        }
        if let str = last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) ") {
            if last.firstMatch("^[\\s]*(-|\\*|\\+|([0-9]+\\.)) +[\\S]+") == nil {
                return "\n"
            }
            guard let range = str.firstMatchRange("[0-9]+") else { return last + "\n" + str }
            let num = str.substring(with: range).toInt() ?? 0
            return last + "\n" + str.replacingCharacters(in: range, with: "\(num+1)")
        }
        if let str = last.firstMatch("^( {4}|\\t)+") {
            return last + "\n" + str
        }
        return last + "\n"
    }
}
import Foundation
