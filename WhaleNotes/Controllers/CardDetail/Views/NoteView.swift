//
//  NoteView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class NoteView: BaseCardEditorView {
    
    private var noteBlock:BlockInfo!
    private var properties:BlockNoteProperty {
        get { return noteBlock.noteProperties! }
        set { noteBlock.noteProperties = newValue }
    }
    private var viewModel:CardEditorViewModel!
    
    let textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.isScrollEnabled = false
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
        $0.textContainerInset = UIEdgeInsets(top: 4, left: 16, bottom: 14, right: 16)
        $0.textContainer.lineFragmentPadding = 0
        $0.backgroundColor = .clear
        $0.isScrollEnabled = true
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .onDrag
    }
    
    init(viewModel:CardEditorViewModel) {
        super.init(frame: .zero)
        self.viewModel = viewModel
        self.noteBlock = viewModel.blockInfo
        self.initializeUI()
        
        textView.text = properties.text
        textView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        addSubview(textView)
        textView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
    }
}

extension NoteView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
//        textChanged?(textView.text)
//        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        textShouldBeginChange?(textView)
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        let text = textView.text ?? ""
        if properties.text != text {
            properties.text = text
            self.updateBlock()
        }
//        textEndEdit?(text)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
//            textEnterReturnKey?()
        }
        return true
    }
}

extension NoteView {
    func updateBlock() {
        self.viewModel.update(block:self.noteBlock.block)
    }
}
