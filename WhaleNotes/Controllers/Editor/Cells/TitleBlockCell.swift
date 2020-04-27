//
//  TitleTableViewCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TitleBlockCell: UITableViewCell {
    
    let textField: UITextField = UITextField().then {
        $0.placeholder = "标题"
        $0.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        $0.textColor = .primaryText
        $0.autocorrectionType = .no
        $0.spellCheckingType = .no
    }
    
    var enterkeyTapped: ((String) -> Void)?
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(EditorViewController.space)
            make.trailing.equalToSuperview().offset(-EditorViewController.space)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-10)
        }
        textField.delegate = self
        self.selectionStyle = .none
    }
    
    var cellHeight: CGFloat {
        get {
            return textField.layer.frame.height + 24
        }
    }
    
    func enterkeyTapped(action: @escaping (String) -> Void) {
        self.enterkeyTapped = action
    }

}

extension TitleBlockCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let enterkeyTapped = self.enterkeyTapped {
            enterkeyTapped(textField.text ?? "")
            return false
        }
        return true
    }
}
