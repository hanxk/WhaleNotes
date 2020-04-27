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
    
    lazy var chkbtn: UIButton = UIButton()
    
     let textView: UITextView = UITextView().then {
        $0.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        $0.textColor = .primaryText
        $0.isEditable = true
        $0.isScrollEnabled = false
        
        $0.textContainerInset = UIEdgeInsets.zero
        $0.textContainer.lineFragmentPadding = 0
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
        
        self.contentView.addSubview(chkbtn)
        self.contentView.addSubview(textView)
//        self.contentView.addSubview(placeHolder)
        
        chkbtn.addTarget(self, action: #selector(handleChkButtonTapped), for: .touchUpInside)
        textView.delegate = self
        
        self.setupConstraints()
    }
    
    private func setupConstraints() {
        
        chkbtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.top.equalToSuperview().offset(4)
            make.leading.equalToSuperview().offset(EditorViewController.space - 2)
        }
        
        textView.snp.makeConstraints { (make) in
            make.leading.equalTo(chkbtn.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }
        
//        placeHolder.snp.makeConstraints { (make) in
//            make.top.equalTo(textView).offset(10)
//            make.leading.equalTo(textView).offset(4)
//        }
    }
    
    @objc private func handleChkButtonTapped() {
        self.isChecked = !self.isChecked
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
}
