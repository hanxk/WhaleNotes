//
//  TextFieldAlertViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/9.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TextFieldAlertViewController: BaseAlertViewController {
    
    var callbackPositive:((String)->Void)?
    
    var placeholder:String = "" {
        didSet {
            textField.placeholder = placeholder
        }
    }
    
    var text:String = "" {
        didSet {
            textField.text = text
        }
    }
    
    private lazy var textField:MyTextField = MyTextField().then {
        $0.placeholder = placeholder
        $0.returnKeyType = .done
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .primaryText
        $0.delegate = self
        $0.layer.cornerRadius = 4
    }
    
    private var boardCategory:BoardCategory?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        contentView.addSubview(textField)
        textField.snp.makeConstraints {
            $0.height.equalTo(38)
            $0.leading.equalToSuperview().offset(10)
            $0.trailing.equalToSuperview().offset(-14)
            $0.top.equalToSuperview().offset(15)
        }
    }
    
    override func positiveBtnTapped() {
        guard let title = textField.text?.trimmingCharacters(in: .whitespaces) else { return }
        if title.isEmpty {
            return
        }
        self.callbackPositive?(title)
        self.dismiss()
    }
}

extension TextFieldAlertViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

// 键盘
extension TextFieldAlertViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHideNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func handleKeyboardNotification(notification: Notification) {
        if let userInfo = notification.userInfo {
            let rect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey]  as! NSValue).cgRectValue
            self.alertView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(-(rect.height + 20))
            }
        }
    }
    
    @objc func handleKeyboardHideNotification(notification: Notification) {
    }
}
