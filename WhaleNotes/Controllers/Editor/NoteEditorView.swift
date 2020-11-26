//
//  NoteEditorView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit


class NoteEditorView: UIView {
    
    private let textViewInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
    
    let textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
        $0.textContainer.lineFragmentPadding = 0
        $0.backgroundColor = .clear
        $0.isScrollEnabled = true
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .onDrag
    }
    
    var textEndEditing:((String)-> Void)?
    
    var text:String{
        set {
            self.textView.text  =  newValue
            placeholderLabel.isHidden = !text.isEmpty
        }
        get {
            return self.textView.text
        }
    }
    
    lazy var placeholderLabel = UILabel().then {
        $0.textColor = .placeholderText
        $0.font = UIFont.systemFont(ofSize: 17)
    }
    
    init(placeholder:String = "") {
        super.init(frame: .zero)
        self.initializeUI()
        textView.delegate = self
        
        placeholderLabel.text = placeholder
        
        textView.textContainerInset = textViewInset
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        self.backgroundColor = .white
        
        addSubview(textView)
        textView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
        
        addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.leading.equalTo(textView.snp.leading).offset(textViewInset.left)
            $0.top.equalTo(textView.snp.top).offset(textViewInset.top)
        }
    }
}

extension NoteEditorView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
//        textChanged?(textView.text)
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        textShouldBeginChange?(textView)
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        let text = textView.text ?? ""
        textEndEditing?(text)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
//            textEnterReturnKey?()
        }
        return true
    }
}

