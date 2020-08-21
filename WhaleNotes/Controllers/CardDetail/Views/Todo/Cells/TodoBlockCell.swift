//
//  TODOItemCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/22.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit

protocol TodoBlockCellDelegate: AnyObject {
    func todoCheckChanged(todoBlock:BlockInfo)
    func todoTextChanged()
    func todoEndEditing(todoBlock:BlockInfo)
    func todoEnterKeyInput(todoBlock:BlockInfo)
    func todoNeedDelete(todoBlock:BlockInfo)
}

class TodoBlockCell: UITableViewCell {
    
    let chkCheckedColor = UIColor.primaryText.withAlphaComponent(0.8)
    
    
    lazy var uncheckedImage: UIImage = UIImage(systemName: "stop", pointSize: 22, weight: .light)!
    lazy var checkedImage: UIImage = UIImage(systemName: "checkmark.square", pointSize: 20, weight: .light)!
    
    var cellHeight: CGFloat = 0
    
    weak var delegate:TodoBlockCellDelegate?
    
    var todoBlock:BlockInfo! {
        didSet {
            self.isChecked = todoBlockPropeties.isChecked
            self.title = todoBlock.title
        }
    }
    
    private var todoBlockPropeties:BlockTodoProperty {
        get { return todoBlock.blockTodoProperties! }
        set { todoBlock.blockTodoProperties = newValue }
    }
    
    private var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.chkbtn.tintColor = .primaryText
                self.chkbtn.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.chkbtn.tintColor = chkCheckedColor
                self.chkbtn.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }
    
    private var title:String = "" {
        didSet {
            self.textView.attributedText = getAttributeText(text: title, isChecked: isChecked)
        }
    }
    
    private func getAttributeText(text:String,isChecked:Bool) -> NSAttributedString {
        let attributedText : NSMutableAttributedString =  NSMutableAttributedString(string: text)
        if isChecked {
            attributedText.addAttributes([
                            NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue,
                            NSAttributedString.Key.strikethroughColor: UIColor.chkCheckedTextColor,
                            NSAttributedString.Key.foregroundColor:UIColor.chkCheckedTextColor,
                            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16.0)
                            ], range: NSMakeRange(0, attributedText.length))
        }else {
            attributedText.addAttributes([
                NSAttributedString.Key.foregroundColor:UIColor.primaryText,
                            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16.0)
                            ], range: NSMakeRange(0, attributedText.length))
        }
        
        return attributedText
    }
    
    
    
    private var isEmpty: Bool = false {
        didSet {
            if isEmpty == true {
                self.chkbtn.tintColor = .lightGray
            } else {
                self.chkbtn.tintColor = self.isChecked ?   .chkCheckedTextColor : .primaryText
            }
            self.chkbtn.isEnabled = !isEmpty
        }
    }
    
    lazy var placeHolder: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .lightGray
        $0.text = "新项目"
    }
    
    lazy var chkbtn: UIButton = UIButton().then {
        $0.addTarget(self, action: #selector(self.handleChkButtonTapped), for: .touchUpInside)
    }
    
    lazy var textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.isScrollEnabled = false
        $0.backgroundColor = .clear
        
        $0.textContainerInset = UIEdgeInsets.zero
        $0.textContainer.lineFragmentPadding = 0
        
        $0.delegate = self
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setup() {
        self.selectionStyle = .none
        
        self.setupUI()
    }
    
    private func setupUI() {
        
        let topSpace:CGFloat = 7.3
        
        self.selectionStyle = .none
        self.contentView.backgroundColor = .clear
        
        self.contentView.addSubview(chkbtn)
        chkbtn.snp.makeConstraints { (make) in
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.leading.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(2)
        }
        
        self.contentView.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.leading.equalTo(chkbtn.snp.trailing).offset(4)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
            make.top.equalToSuperview().offset(topSpace)
            make.bottom.equalToSuperview().offset(-topSpace)
        }
    }
    
    @objc private func handleChkButtonTapped() {
        self.todoBlockPropeties.isChecked = !self.isChecked
        delegate?.todoCheckChanged(todoBlock: self.todoBlock)
    }
}

extension TodoBlockCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        isEmpty = textView.text.isEmpty
        self.todoBlock.title = textView.text.trimmingCharacters(in: .whitespaces)
        delegate?.todoTextChanged()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        let text = textView.text ?? ""
        if text.isEmpty {
            delegate?.todoNeedDelete(todoBlock: self.todoBlock)
            return true
        }
        delegate?.todoEndEditing(todoBlock: self.todoBlock)
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            delegate?.todoEnterKeyInput(todoBlock: self.todoBlock)
            return false
        }
        if text.isEmpty && textView.text.isEmpty {
            delegate?.todoNeedDelete(todoBlock: self.todoBlock)
            return false
        }
        return true
    }
    
}
