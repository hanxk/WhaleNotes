//
//  BoardSettingTitleCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BoardSettingTitleCell: UITableViewCell {
    
    var callbackTitleChanged:((String)->Void)?
    
    private lazy var titleTextField = UITextField().then {
        $0.textColor = .primaryText2
        $0.font = UIFont.systemFont(ofSize: 15)
        $0.placeholder = "输入名称"
        $0.clearButtonMode = .whileEditing
        $0.returnKeyType = .done
//        $0.delegate = self
        $0.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

    }
    
    var title:String = "" {
        didSet {
            self.titleTextField.text = title
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        callbackTitleChanged?(textField.text?.trimmingCharacters(in: .whitespaces) ?? "")
    }
    
    private func setup() {
        self.contentView.addSubview(titleTextField)
        titleTextField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(BoardSettingViewController.horizontalPadding)
            $0.trailing.equalToSuperview().offset(-BoardSettingViewController.horizontalPadding)
            $0.top.bottom.equalToSuperview()
        }
        
    }
    
}

extension BoardSettingTitleCell: UITextFieldDelegate {
  
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        let title = textField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        callbackTitleChanged?(title)
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
