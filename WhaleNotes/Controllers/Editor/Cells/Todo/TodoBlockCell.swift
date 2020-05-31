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
    func textDidChange()
    func todoBlockEnterKeyInput(newBlock:Block2)
    func todoBlockNeedDelete(newBlock:Block2)
    func todoBlockContentChange(newBlock:Block2)
}

class TodoBlockCell: UITableViewCell {
    
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .light)
    
    lazy var uncheckedImage: UIImage = UIImage(systemName: "stop",withConfiguration: config)!
    lazy var checkedImage: UIImage = UIImage(systemName: "checkmark.square.fill",withConfiguration: config)!
    
    var cellHeight: CGFloat = 0
    
    weak var delegate:TodoBlockCellDelegate?
    
    
//    var enterkeyTapped: ((Block2) -> Void)?
//    var blockUpdated:((Block2) -> Void)?
//    var blockNeedDeleted:((Block2) -> Void)?
    
    var todoBlock: Block2!{
        didSet {
//            textView.text = todoBlock.text + "******* " + String(todoBlock.sort)
             textView.text = todoBlock.text
            isChecked = todoBlock.isChecked
            isEmpty = todoBlock.text.isEmpty
        }
    }
    var note:NoteInfo!
    
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.chkbtn.tintColor = .brand
                self.chkbtn.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.chkbtn.tintColor = .buttonTintColor
                self.chkbtn.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }
    
    var isEmpty: Bool = false {
        didSet {
            if isEmpty == true {
                self.chkbtn.tintColor = .lightGray
            } else {
                self.chkbtn.tintColor = self.isChecked ? UIColor.brand : UIColor.buttonTintColor
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
//        $0.backgroundColor = .red
    }
    
    lazy var textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.isScrollEnabled = false
        
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
        self.isChecked = !self.isChecked
        self.todoBlock.isChecked = self.isChecked
        delegate?.todoBlockContentChange(newBlock: self.todoBlock)
    }
}

extension TodoBlockCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        isEmpty = textView.text.isEmpty
        delegate?.textDidChange()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        let text = textView.text ?? ""
        if  text != todoBlock.text {
            self.todoBlock.text = text
            delegate?.todoBlockContentChange(newBlock: self.todoBlock)
        }
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let text = textView.text ?? ""
            self.todoBlock.text = text
            delegate?.todoBlockEnterKeyInput(newBlock: self.todoBlock)
            return false
        }
        if text.isEmpty && textView.text.isEmpty {
            self.todoBlock.text = ""
            delegate?.todoBlockNeedDelete(newBlock: self.todoBlock)
            return false
        }
        return true
    }
    
}
