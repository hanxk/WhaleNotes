//
//  FormCommonCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/11/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class FormCommonCell: UITableViewCell {
    
    var callbackTitleChanged:((String)->Void)?
    
    lazy var iconView = UIImageView().then {
        
        $0.tintColor = .iconColor
    }
    lazy var titleLabel = UILabel().then {
        $0.textColor = .primaryText
        $0.font = .systemFont(ofSize: 15)
    }
    lazy var valueLabel = UILabel().then {
        $0.textColor = .primaryText
        $0.font = .systemFont(ofSize: 15)
    }
    
    var icon:String = "" {
        didSet {
            iconView.image = UIImage(systemName: icon, pointSize: 15)
        }
    }
    
    var title:String = "asdasdassd" {
        didSet {
            titleLabel.text = title
        }
    }
    var value:String = "" {
        didSet {
            valueLabel.text = value
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
        self.selectionStyle = .none
        self.contentView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(BoardSettingViewController.horizontalPadding)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(24)
        }
        
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(iconView.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
        }
        
        
    }
    
}

extension FormCommonCell: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
           return true
    }
}
