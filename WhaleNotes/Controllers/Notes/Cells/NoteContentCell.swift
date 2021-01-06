//
//  NoteContentCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/29.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
class NoteContentCell: UITableViewCell {
    
    lazy var textView = MDTextView(frame: .zero).then {
        $0.isScrollEnabled = false
        $0.editorDelegate = self
        $0.textContainerInset = UIEdgeInsets(top: 0, left: EditorViewController.space, bottom: 20, right: EditorViewController.space)
        $0.textContainer.lineFragmentPadding = 0
    }
    
    private var textChanged: ((String) -> Void)?
    private var textDidFinishEditing: ((String) -> Void)?
    private var textEnterkeyInput: (() -> Void)?
    private var tagTapped: ((String) -> Void)?
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
        }
        textView.typingAttributes = MarkdownAttributes.mdDefaultAttributes
        self.selectionStyle = .none
    }
    
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
    
    func textDidFinishEditing(action: @escaping (String) -> Void) {
        self.textDidFinishEditing = action
    }
    func textEnterkeyInput(action: @escaping () -> Void) {
        self.textEnterkeyInput = action
    }
    func tagTapped(action: @escaping (String) -> Void) {
        self.tagTapped = action
    }
}

extension NoteContentCell: MarkdownTextViewDelegate {
    func textViewDidChange(_ textView: MDTextView) {
        self.textChanged?(textView.text)
    }
    
    func textViewDidEndEditing(_ textView: MDTextView) {
        self.textDidFinishEditing?(textView.text)
    }
    func textViewTagTapped(_ textView: MDTextView, tag: String) {
        
    }
    func textViewLinkTapped(_ textView: MDTextView, link: String) {
        if let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}
