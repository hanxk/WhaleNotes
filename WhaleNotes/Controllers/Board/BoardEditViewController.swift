//
//  BoardEditViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BoardEditViewController: BaseAlertViewController {
    
    static func showModel(vc: UIViewController) {
        let editVC = BoardEditViewController()
        editVC.modalPresentationStyle = .overFullScreen
        editVC.modalTransitionStyle = .crossDissolve
        vc.present(editVC, animated: true, completion: nil)
    }
    
    private lazy var emojiButton:UIButton = UIButton().then {
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        $0.titleLabel?.textAlignment = .center
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(hexString: "#ECECEC").cgColor
        $0.layer.cornerRadius = 4
        $0.addTarget(self, action: #selector(self.emojiButtonTapped), for: .touchUpInside)
    }
    
    private lazy var textField:MyTextField = MyTextField().then {
        $0.placeholder = "输入名称"
        $0.returnKeyType = .done
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textColor = .primaryText
        $0.delegate = self
        $0.layer.cornerRadius = 4
    }
    
    private var emoji:Emoji? {
        didSet {
            if let emoji = emoji {
                self.emojiButton.setTitle(emoji.value, for: .normal)
            }
        }
    }
    
    private var board:Board?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        EmojiRepo.shared.randomEmoji { [weak self] emoji in
            self?.emoji = emoji
        }
        
        if board == nil {
            self.alertTitle = "添加便签板"
        }
    }
    
    private func setupUI() {
        
        contentView.addSubview(emojiButton)
        emojiButton.snp.makeConstraints {
            $0.width.height.equalTo(38)
            $0.leading.equalToSuperview().offset(14)
            $0.top.equalToSuperview().offset(15)
        }
        
        contentView.addSubview(textField)
        textField.snp.makeConstraints {
            $0.height.equalTo(emojiButton.snp.height)
            $0.leading.equalTo(emojiButton.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().offset(-14)
            $0.top.equalTo(emojiButton.snp.top)
        }
    }
}

extension BoardEditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func emojiButtonTapped() {
        let vc = EmojiViewController()
        vc.callbackEmojiSelected = { [weak self] emoji in
            self?.emoji = emoji
        }
        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
    }
    
    func categoryItemTapped() {
        self.navigationController?.pushViewController(BoardCategoryViewController(), animated: true)
    }
}




// 键盘
extension BoardEditViewController {
    
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
//        if let userInfo = notification.userInfo {
//            guard let view = self.view else{
//                return
//            }
//        }
    }
}
