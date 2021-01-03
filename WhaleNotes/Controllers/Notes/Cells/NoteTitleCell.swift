//
//  NoteTitleCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/29.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
class NoteTitleCell: UITableViewCell {
    
    let textView: UITextView = UITextView().then {
//        $0.placeholder = "标题"
        $0.font = MarkdownAttributes.headerFont2
        $0.textColor = .primaryText
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
        $0.isScrollEnabled = false
        
        $0.textContainerInset = UIEdgeInsets(top: 0, left: EditorViewController.space, bottom: 0, right: EditorViewController.space)
        $0.textContainer.lineFragmentPadding = 0
    }
    
    private var textChanged: ((String) -> Void)?
    private var textDidFinishEditing: ((String) -> Void)?
    private var textEnterkeyInput: (() -> Void)?
    
    
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
//            make.leading.equalToSuperview().offset(EditorViewController.space)
//            make.trailing.equalToSuperview().offset(-EditorViewController.space)
//            make.top.equalToSuperview()
//            make.bottom.equalToSuperview()
            make.width.height.equalToSuperview()
        }
//        self.backgroundColor = .blue
        textView.delegate = self
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
}

extension NoteTitleCell: UITextViewDelegate {
   
    func textViewDidChange(_ textView: UITextView) {
        self.textChanged?(textView.text)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        self.textDidFinishEditing?(textView.text)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textEnterkeyInput?()
            return  false
        }
        return  true
    }
    
}
