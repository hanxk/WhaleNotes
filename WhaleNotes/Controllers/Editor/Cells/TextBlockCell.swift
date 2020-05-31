//
//  NoteContentViewCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift

class TextBlockCell: UITableViewCell {
    
    let textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.isScrollEnabled = false
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
        $0.textContainerInset = UIEdgeInsets.zero
        $0.textContainer.lineFragmentPadding = 0
    }
    var textChanged: ((String) -> Void)?
    var blockUpdated:((Block) -> Void)?
    
    private lazy var disposebag = DisposeBag()
    
    private var textBlock: Block! {
        didSet {
            textView.text = textBlock.text
            placeholderLabel.isHidden = textBlock.text.isNotEmpty
        }
    }
    
    var note:NoteInfo! {
        didSet {
            if let textBlock = note.textBlock {
                self.textBlock = textBlock
            }
        }
    }
    
    
    let placeholderLabel = UILabel().then {
        $0.textColor = .lightGray
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.text = "写点什么..."
    }
    
    var textShouldBeginChange: ((UITextView) -> Void)?
    var textEnterReturnKey: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func textChanged(action: @escaping (String) -> Void) {
        self.textChanged = action
    }
    
    //    func textShouldBeginChange(action: @escaping (UITextView) -> Void) {
    //        self.textShouldBeginChange = action
    //    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        textChanged = nil
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textView.delegate = self
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        //        self.selectionStyle = .none
        _setSpacing(textView: textView, fontSize: 17, lineSpacing: 1, weight: .regular)
        contentView.addSubview(textView)
        textView.delegate = self
        textView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(EditorViewController.space)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
            make.top.bottom.equalToSuperview()
        }
        contentView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(EditorViewController.space)
            make.top.equalToSuperview()
        }
    }
    
    func _setSpacing(textView:UITextView,fontSize:CGFloat,lineSpacing:CGFloat,weight:UIFont.Weight) {
        let spacing = NSMutableParagraphStyle()
        spacing.lineSpacing = lineSpacing
        let attr = [NSAttributedString.Key.paragraphStyle : spacing,
                    NSAttributedString.Key.foregroundColor: UIColor.primaryText,
                    NSAttributedString.Key.font:UIFont.systemFont(ofSize: fontSize, weight: weight)
        ]
        textView.typingAttributes = attr
    }
    
}

extension TextBlockCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textChanged?(textView.text)
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textShouldBeginChange?(textView)
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        let text = textView.text ?? ""
        if  text != textBlock.text {
            self.textBlock.text = text
            blockUpdated?(self.textBlock)
        }
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textEnterReturnKey?()
        }
        return true
    }
}
