//
//  NoteEditorView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift
import EZSwiftExtensions

class MDEditorView: UIView {
    
    private let textViewInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    var highlightmanager = MarkdownHighlightManager()
    
    let editView: TextView = TextView().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.keyboardDismissMode = .onDrag
        $0.alwaysBounceVertical = true
        $0.textContainer.lineBreakMode = .byCharWrapping
    }
    
    
    lazy var placeholderLabel = UILabel().then {
        $0.textColor = .placeholderText
        $0.font = UIFont.systemFont(ofSize: 17)
        
    }
    
    var placeholder:String {
        set {
            let paragraphStyle = { () -> NSMutableParagraphStyle in
                let paraStyle = NSMutableParagraphStyle()
                paraStyle.maximumLineHeight = 23
                paraStyle.minimumLineHeight = 23
                paraStyle.lineSpacing = 3
                return paraStyle
            }()
            
            let myAttribute:[NSAttributedString.Key:Any] = [
                .foregroundColor: UIColor.placeholderText,
                .paragraphStyle : paragraphStyle
            ]
            let myAttrString = NSAttributedString(string: newValue, attributes: myAttribute)
            placeholderLabel.attributedText = myAttrString
        }
        
        get {
            return placeholderLabel.text ?? ""
        }
    }
    
    
    let markdownRenderer = MarkdownRender.shared()
    
    var lastOffsetY: CGFloat = 0.0
    var timer: Timer?
    let bag = DisposeBag()
    
    
    var _textHeight: CGFloat = 0
    
    var _textWidth: CGFloat = 0
    var contentHeight: CGFloat {
//        if _textWidth != editView.w {
//            _textWidth = editView.w
//            let w = _textWidth - editView.contentInset.left * 2
//            _textHeight = editView.sizeThatFits(editView.contentSize).height + editView.contentInset.bottom
//        }
        return editView.contentSize.height
    }
    var offset: CGFloat = 0.0 {
        didSet {
            var y = offset * (contentHeight - editView.h)
            if y > contentHeight - editView.h  {
                y = contentHeight - editView.h
            }
            if y < 0 {
                y = 0
            }
            editView.contentOffset = CGPoint(x: editView.contentOffset.x,y: y)
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
    
    var textEndEditing:((String)-> Void)?
    var textChangedHandler: ((String)->Void)?
    
    var text:String{
        set {
            self.editView.text  =  newValue
        }
        get {
            return self.editView.text
        }
    }
    
    var shouldRender = false
    
    var isRendering = false {
        didSet {
            if isRendering {
                DispatchQueue.global().async { [weak self] in
                    let html = self?.markdownRenderer?.renderMarkdown(self?.editView.text) ?? ""
                    DispatchQueue.main.async {
//                        self?.previewVC.html = html
                        self?.isRendering = false
                    }
                }
                shouldRender = false
            } else {
                if shouldRender {
                    DispatchQueue.main.async {
                        self.isRendering = true
                    }
                }
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.initializeUI()
        editView.delegate = self
        
        editView.textContainerInset = textViewInset
        editView.viewController = self.controller
        editView.delegate = self
        
        
        setupRx()
        
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        self.backgroundColor = .white
        
        addSubview(editView)
        editView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
        
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.leading.equalTo(editView.snp.leading).offset(textViewInset.left+3)
            $0.top.equalTo(editView.snp.top).offset(textViewInset.top)
        }
        
    }
    
    
    deinit {
        timer?.invalidate()
//        removeNotificationObserver()
        print("deinit text_vc")
    }
    
    
    func setup() {
//        guard let file = self.file else {
//            return
//        }
//
//        if isViewLoaded == false {
//            return
//        }
                
//        emptyView.isHidden = true

//        previewVC.htmlURL = URL(fileURLWithPath: file.path).deletingLastPathComponent().appendingPathComponent(".\(file.displayName).html")
//
//        textVC.editView.file = file
//
//        textVC.textChangedHandler = { [weak self] (text) in
//            file.text = text
//            self?.redoButton.isEnabled = self?.textVC.editView.undoManager?.canRedo ?? false
//            self?.undoButton.isEnabled = self?.textVC.editView.undoManager?.canUndo ?? false
//            self?.render()
//        }
//
//        textVC.didScrollHandler = { [weak self] offset in
//            self?.previewVC.offset = offset
//        }
//
//        previewVC.didScrollHandler = { [weak self] offset in
//            self?.textVC.offset = offset
//        }
        
        Configure.shared.markdownStyle.asObservable().subscribe(onNext: { [weak self] (style) in
            self?.markdownRenderer?.styleName = style
            self?.render()
        }).disposed(by: bag)
        
        Configure.shared.fontSize.asObservable().subscribe(onNext: { [weak self] fontSize in
            self?.markdownRenderer?.fontSize = fontSize
            self?.render()
        }).disposed(by: bag)
        
        Configure.shared.highlightStyle.asObservable().subscribe(onNext: { [weak self] (style) in
            self?.markdownRenderer?.highlightName = style
            self?.render()
        }).disposed(by: bag)
        
        Configure.shared.automaticSplit.asObservable().subscribe(onNext: { [weak self] (split) in
            guard let this = self else { return }
//            this.editViewWidth.isActive = split ? this.view.w > this.view.h * 0.8 : false
//            this.seperator.isHidden = this.editViewWidth.isActive.toggled
        }).disposed(by: bag)
        
        Configure.shared.autoHideNavigationBar.asObservable().subscribe(onNext: { [weak self] (autoHide) in
            if !autoHide {
//                self?.navigationController?.setNavigationBarHidden(false, animated: true)
            }
        }).disposed(by: bag)
        
//        let line = UIView()
//        line.backgroundColor = rgba("262626",0.4)
//        view.addSubview(line)
//        line.snp.makeConstraints { maker in
//            maker.top.left.right.equalTo(self.bottomBar)
//            maker.height.equalTo(0.3)
//        }
        
        loadText(editView.text)
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
}

extension MDEditorView {
    
    func setupRx() {
        
        Configure.shared.isAssistBarEnabled.asObservable().subscribe(onNext: { [unowned self](enable) in
            if enable {
//                self.assistBar.textView = self.editView
//                self.editView.inputAccessoryView = self.assistBar
            } else {
                self.editView.inputAccessoryView = nil
            }
        }).disposed(by: bag)
        
        Configure.shared.theme.asObservable().subscribe(onNext: { [unowned self] _ in
            self.highlightmanager = MarkdownHighlightManager()
            self.textViewDidChange(self.editView)
        }).disposed(by: bag)
        
        Configure.shared.fontSize.asObservable().subscribe(onNext: { [unowned self] (size) in
            HighlightStyle.boldFont = UIFont.monospacedDigitSystemFont(ofSize: CGFloat(size), weight: UIFont.Weight.medium)
            HighlightStyle.normalFont = UIFont.monospacedDigitSystemFont(ofSize: CGFloat(size), weight: UIFont.Weight.regular)
            self.highlightmanager = MarkdownHighlightManager()
            self.textViewDidChange(self.editView)
        }).disposed(by: bag)
    }
}


extension MDEditorView: UITextViewDelegate {
    
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
        if editView.text.count < 5000 {
            return
        }
        if fabs(scrollView.contentOffset.y - lastOffsetY) < 500 {
            return
        }
        timer?.invalidate()
        let contentOffset = editView.contentOffset
        highlight()
        editView.contentOffset = contentOffset
        lastOffsetY = scrollView.contentOffset.y
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
        textEndEditing?(textView.text)
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
        placeholderLabel.isHidden = !text.isEmpty
        if editView.markedTextRange != nil {
            return
        }
        textChangedHandler?(text)

        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(highlight), userInfo: nil, repeats: false)
        _textWidth = 0
    }
}
extension NSRange {
    func toTextRange(textInput:UITextInput) -> UITextRange? {
        if let rangeStart = textInput.position(from: textInput.beginningOfDocument, offset: location),
            let rangeEnd = textInput.position(from: rangeStart, offset: length) {
            return textInput.textRange(from: rangeStart, to: rangeEnd)
        }
        return nil
    }
}
extension String {
    /// Fixes the problem with `NSRange` to `Range` conversion
    var range: NSRange {
        let fromIndex = unicodeScalars.index(unicodeScalars.startIndex, offsetBy: 0)
        let toIndex = unicodeScalars.index(fromIndex, offsetBy: count)
        return NSRange(fromIndex..<toIndex, in: self)
    }
}

extension MDEditorView {
    
    @objc func highlight() {
        if editView.text.count < 5000 {
            highlightmanager.highlight(editView.textStorage,visibleRange: nil)
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
