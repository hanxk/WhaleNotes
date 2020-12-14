//
//  MDToolbar.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class MDToolbar: UIView {
    
    enum ActionType:Int {
        case header = 1
        case list = 2
        case numList = 3
        case keyboard = 0
    }
    
    init() {
        super.init(frame: .zero)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var actionButtonTapped:((ActionType)-> Void)?
    
    private func setupUI() {
        
        let buttonSize:CGFloat = 28
        let spacing:CGFloat = 22
        let insetHori:CGFloat = 14
        
        let headerButton = generateToolButton(imgName: "grid", tag: .header)
        self.addSubview(headerButton)
        headerButton.snp.makeConstraints {
            $0.width.height.equalTo(buttonSize)
            $0.leading.equalToSuperview().offset(insetHori)
            $0.centerY.equalToSuperview()
        }
        
        
        let listButton = generateToolButton(imgName: "list.dash", tag: .list)
        self.addSubview(listButton)
        listButton.snp.makeConstraints {
            $0.width.height.equalTo(buttonSize)
            $0.leading.equalTo(headerButton.snp.trailing).offset(spacing)
            $0.centerY.equalToSuperview()
        }
        
        
        let numListButton = generateToolButton(imgName: "list.number", tag: .numList)
        self.addSubview(numListButton)
        numListButton.snp.makeConstraints {
            $0.width.height.equalTo(buttonSize)
            $0.leading.equalTo(listButton.snp.trailing).offset(spacing)
            $0.centerY.equalToSuperview()
        }
        
        
        let keyboardButton = generateToolButton(imgName: "keyboard.chevron.compact.down", tag: .keyboard)
        self.addSubview(keyboardButton)
        keyboardButton.snp.makeConstraints {
            $0.width.height.equalTo(buttonSize)
            $0.trailing.equalToSuperview().offset(-insetHori)
            $0.centerY.equalToSuperview()
        }
        self.backgroundColor = .white
        self.layer.shadowColor = UIColor(red: 0.875, green: 0.875, blue: 0.875, alpha: 1).cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 0
        self.layer.shadowOffset = CGSize(width: 0, height: -1)
        
    }
}

extension MDToolbar {
    private func generateToolButton(imgName:String, tag: ActionType) -> UIButton {
        let button = UIButton(type: .custom).then {
            let img = UIImage(systemName: imgName, pointSize: 19)!.withRenderingMode(.alwaysTemplate)
            $0.setImage(img, for: .normal)
            $0.tag = tag.rawValue
            $0.addTarget(self, action: #selector(handleActionButtonTapped), for: .touchUpInside)
            $0.tintColor = UIColor(hexString: "#545454")
        }
        return button
    }
    
    @objc func handleActionButtonTapped(sender: UIButton) {
        guard let actionType = ActionType(rawValue: sender.tag) else { return }
        actionButtonTapped?(actionType)
    }
}
