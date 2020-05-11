//
//  TODOItemCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/22.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit
import RealmSwift

class TodoBlockCell: UITableViewCell {
    
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .light)
    
    lazy var uncheckedImage: UIImage = UIImage(systemName: "stop",withConfiguration: config)!
    lazy var checkedImage: UIImage = UIImage(systemName: "checkmark.square.fill",withConfiguration: config)!
    
    var cellHeight: CGFloat = 0
    
    
    var todoGroupBlock:Block!
    
    private var todoBlocks: List<Block> {
        return self.todoGroupBlock.blocks
    }
    
    var todoBlock: Block!{
        didSet {
            textView.text = todoBlock.text
            isChecked = todoBlock.isChecked
            isEmpty = todoBlock.text.isEmpty
        }
    }
    var note:Note!
    
    
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
    var textChanged: ((UITextView) -> Void)?
    var textShouldBeginChange: (() -> Void)?
    var textViewShouldEndEditing: (() -> Void)?
    
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
            make.leading.equalTo(chkbtn.snp.trailing).offset(6)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
            make.top.equalToSuperview().offset(topSpace)
            make.bottom.equalToSuperview().offset(-topSpace)
        }
    }
    
    @objc private func handleChkButtonTapped() {
        self.isChecked = !self.isChecked
        self.textView.resignFirstResponder()
        DBManager.sharedInstance.update { [weak self] in
            guard let self = self else { return }
            self.todoBlock.text = textView.text.trimmingCharacters(in: .whitespaces)
            self.todoBlock.isChecked = self.isChecked
        }
    }
}

extension TodoBlockCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textChanged?(textView)
        isEmpty = textView.text.isEmpty
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textShouldBeginChange?()
        return true
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textViewShouldEndEditing?()
        if isEmpty {
            self.deleteTodo()
            return true
        }
        self.updateTodo()
        return true
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.handleEnterReturn(textView: textView)
            return false
        }
        if text.isEmpty && textView.text.isEmpty {
            self.deleteTodo()
            return false
        }
        return true
    }
    
    private func updateTodo() {
        DBManager.sharedInstance.update { [weak self] in
            guard let self = self else { return }
            self.todoBlock.text = self.textView.text.trimmingCharacters(in: .whitespaces)
        }
    }
    
}

// uitextview enter return key
extension TodoBlockCell {
    
    private func handleEnterReturn(textView: UITextView) {
        let text = textView.text ?? ""
        if text.isEmpty {
            // 删除todo
            self.deleteTodo()
        }else{
            guard  let currentIndex = self.todoBlocks.index(of: self.todoBlock) else { return }
            let destIndex = currentIndex + 1
            
            // 新增todo
            Logger.info("新增todo")
            DBManager.sharedInstance.update { [weak self] in
                guard let self = self else { return }
                self.todoBlock.text = text
                todoBlocks.insert(Block.newTodoBlock(), at: destIndex)
            }
        }
    }
    
    private func deleteTodo() {
        Logger.info("删除todo")
        DBManager.sharedInstance.update { [weak self] in
            guard let self = self else { return }
            if let index = todoBlocks.firstIndex(of: self.todoBlock) {
                todoBlocks.remove(at: index)
            }
        }
    }
    
}
