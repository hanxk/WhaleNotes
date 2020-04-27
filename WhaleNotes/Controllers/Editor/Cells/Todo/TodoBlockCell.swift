//
//  TODOItemCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/22.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit

class TodoBlockCell: UITableViewCell {
    
    let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
    
    lazy var uncheckedImage: UIImage = UIImage(systemName: "stop",withConfiguration: config)!
    lazy var checkedImage: UIImage = UIImage(systemName: "checkmark.square.fill",withConfiguration: config)!
    
    var cellHeight: CGFloat = 0
    var todo: Todo! {
        didSet {
            textView.text = todo.text
            isChecked = todo.isChecked
        }
    }
    var todoBlock: Block!
    
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
        }
    }
    
    lazy var placeHolder: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .lightGray
        $0.text = "新项目"
    }
    
    lazy var chkbtn: UIButton = UIButton().then {
        $0.addTarget(self, action: #selector(self.handleChkButtonTapped), for: .touchUpInside)
    }
    
    lazy var textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.isScrollEnabled = false
        
        $0.textContainerInset = UIEdgeInsets.zero
        $0.textContainer.lineFragmentPadding = 0
        
        $0.delegate = self
    }
    var textChanged: ((UITextView) -> Void)?
    var textShouldBeginChange: ((UITextView) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.selectionStyle = .none
        self.isChecked = false
        self.isEmpty = true
        
        self.setupUI()
    }
    
    private func setupUI() {
        
        self.contentView.addSubview(chkbtn)
        chkbtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(EditorViewController.space - 2)
        }
        
        self.contentView.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.leading.equalTo(chkbtn.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }
    }
    
    @objc private func handleChkButtonTapped() {
        self.isChecked = !self.isChecked
        DBManager.sharedInstance.update { [weak self] in
            guard let self = self else { return }
            self.updateCheck()
        }
    }
    private func updateCheck() {
//        let todos = self.todoBlock.todos
//        guard let from = todos.firstIndex(of: self.todo) else { return }
//        if self.isChecked { // 移动到底部
//            if let to =  todos.lastIndex(where: { !($0.isChecked) }) {
//                todos.move(from: from, to: to)
//            }
//        }
//        else {
//            
//        }
        self.todo.isChecked = self.isChecked
    }
}

extension TodoBlockCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textChanged?(textView)
        isEmpty = textView.text.isEmpty
    }
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textShouldBeginChange?(textView)
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
    
}

// uitextview enter return key
extension TodoBlockCell {
    
    private func handleEnterReturn(textView: UITextView) {
        let text = textView.text ?? ""
        if text.isEmpty {
            // 删除todo
            self.deleteTodo()
        }else {
            // 新增todo
            Logger.info("新增todo")
            DBManager.sharedInstance.update { [weak self] in
                guard let self = self else { return }
                self.todo.text = text
                let todos = self.todoBlock.todos
                if let index =  todos.firstIndex(of: self.todo) {
                    todos.insert(Todo(text: "", block: todoBlock), at: index+1)
                }
            }
        }
    }
    
    private func deleteTodo() {
        Logger.info("删除todo")
        DBManager.sharedInstance.update { [weak self] in
            guard let self = self else { return }
            if let index = self.todoBlock.todos.firstIndex(of: self.todo) {
                self.todoBlock.todos.remove(at: index)
            }
        }
    }
    
}
