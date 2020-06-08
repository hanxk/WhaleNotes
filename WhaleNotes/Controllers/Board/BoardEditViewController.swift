//
//  BoardEditViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BoardEditViewController: UIViewController {
    
    private lazy var emojiButton:UIButton = UIButton().then {
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 60)
        $0.titleLabel?.textAlignment = .center
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(hexString: "#ECECEC").cgColor
        $0.layer.cornerRadius = 8
        $0.addTarget(self, action: #selector(self.emojiButtonTapped), for: .touchUpInside)
    }
    
    private lazy var textField:MyTextField = MyTextField().then {
        $0.placeholder = "输入名称"
        $0.returnKeyType = .done
        $0.delegate = self
    }
    
    private lazy var categoryItemView:BoardSettingItemView = BoardSettingItemView().then {
        $0.callbackViewTapped = {
            self.categoryItemTapped()
        }
    }
    
    private var emoji:Emoji? {
        didSet {
            if let emoji = emoji {
                self.emojiButton.setTitle(emoji.value, for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "添加便签板"
       
        self.navigationItem.leftBarButtonItem =  UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(self.cancelButtonTapped))
        
        let barButtonItem = UIBarButtonItem(title: "完成", style: .done, target: self, action: #selector(self.doneButtonTapped))
        barButtonItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.brand], for: .normal)
        self.navigationItem.rightBarButtonItem = barButtonItem
        
        EmojiRepo.shared.randomEmoji { [weak self] emoji in
            self?.emoji = emoji
        }
        
        self.setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.becomeFirstResponder()
    }
    
    @objc func cancelButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    @objc func doneButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setupUI() {
        self.view.addSubview(emojiButton)
        emojiButton.snp.makeConstraints {
            $0.width.height.equalTo(80)
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(26)
        }
        
        
        self.view.addSubview(textField)
        textField.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.height.equalTo(48)
            $0.top.equalTo(emojiButton.snp.bottom).offset(34)
        }
        
        self.view.addSubview(categoryItemView)
        categoryItemView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.height.equalTo(44)
            $0.top.equalTo(textField.snp.bottom).offset(20)
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
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
   func categoryItemTapped() {
        self.navigationController?.pushViewController(BoardCategoryViewController(), animated: true)
    }
}
