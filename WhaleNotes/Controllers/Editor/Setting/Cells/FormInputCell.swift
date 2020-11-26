//
//  FormInputCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class FormInputCell: UITableViewCell {
    
    var textChanged: ((String) -> Void)?
    
    let topPadding:CGFloat = 12
    
    lazy var textView = UITextView().then {
        $0.textColor = .primaryText
        $0.font = UIFont.systemFont(ofSize: 15)
        $0.returnKeyType = .done
        $0.delegate = self
        $0.isScrollEnabled = false
        $0.bounces = false
        $0.textContainerInset = UIEdgeInsets(top: topPadding, left: 0, bottom: topPadding, right: 0)
        $0.textContainer.lineFragmentPadding = 0
    }
    lazy var placeholderLabel = UILabel().then {
        $0.textColor = .placeholderText
        $0.font = UIFont.systemFont(ofSize: 15)
    }
    
    
    var placeHolder:String!{
        didSet {
            placeholderLabel.text = placeHolder
        }
    }
    
    var lines:Int = 1 {
        didSet {
            textView.textContainer.maximumNumberOfLines = lines
            
        }
    }
    
    var maxLines:Int = 1 {
        didSet {
            textView.textContainer.maximumNumberOfLines = maxLines
            if maxLines  == 1 {
                textView.textContainer.lineBreakMode = .byTruncatingTail
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        self.selectionStyle = .none
        self.contentView.addSubview(textView)
        textView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(BoardSettingViewController.horizontalPadding)
            $0.trailing.equalToSuperview().offset(-BoardSettingViewController.horizontalPadding)
            $0.top.bottom.equalToSuperview()
            $0.height.greaterThanOrEqualTo(44)
        }
        
        self.contentView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.leading.equalTo(textView.snp.leading).offset(2)
            $0.top.equalTo(textView.snp.top).offset(topPadding)
        }
        
        
    }
    
}
extension FormInputCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        textChanged?(textView.text)
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
//        textShouldBeginChange?(textView)
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
//        let text = textView.text ?? ""
//        if properties.text != text {
//            properties.text = text
//            self.updateBlock()
//        }
//        textEndEdit?(text)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" && maxLines == 1{
            
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
