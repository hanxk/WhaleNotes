//
//  EmojiSearchInputView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/8.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class EmojiSearchInputView: UIView {
    
    var callbackTextInputChanged:((String) -> Void)?
    
    lazy var textField:MyTextField = MyTextField().then {
        $0.placeholder = "搜索图标"
        $0.returnKeyType = .done
        $0.delegate = self
        $0.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(textField)
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.trailing.equalToSuperview().offset(-14)
            $0.height.equalTo(40)
            $0.centerY.equalToSuperview()
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

    @objc func textFieldDidChange(_ textField: UITextField) {
        callbackTextInputChanged?(textField.text?.trimmingCharacters(in: .whitespaces) ?? "")
    }
}

extension EmojiSearchInputView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
         textField.resignFirstResponder()
         return true
     }
}
