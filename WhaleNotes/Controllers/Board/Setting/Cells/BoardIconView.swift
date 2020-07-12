//
//  BoardIconView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BoardIconView: UITableViewHeaderFooterView {
    
    var callbackTapped:(()->Void)?
    
    private lazy var iconButton = UIButton().then {
        $0.backgroundColor = UIColor.white
        $0.layer.borderWidth = 0.5
        $0.layer.borderColor = UIColor(hexString: "#DDDDDD").cgColor
        $0.layer.cornerRadius = 10
        $0.tintColor = UIColor(hexString: "#666666")
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    private lazy var changeButton = UIButton().then {
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 13,weight: .medium)
        $0.setTitle("更换图标", for: .normal)
        $0.setTitleColor(.brand, for: .normal)
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    var isEdited:Bool! = true  {
        didSet {
            changeButton.isHidden = !isEdited
        }
    }
    
    
    var iconImage:UIImage! {
        didSet {
            iconButton.setImage(iconImage, for: .normal)
        }
    }
    
//    var board:Board! {
//        didSet {
//
//        }
//    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func buttonTapped() {
        if isEdited {
            self.callbackTapped?()
        }
    }
    
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        self.addSubview(iconButton)
        iconButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(80)
            $0.top.equalToSuperview().offset(24)
        }
        
        self.addSubview(changeButton)
        changeButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.equalTo(iconButton.snp.width)
            $0.height.equalTo(32)
            $0.top.equalTo(iconButton.snp.bottom).offset(4)
        }
        
    }
    
    static func getCellHeight(board:Board) -> CGFloat {
//        return board.type == BoardType.user.rawValue ? 154 : 122
        return 122
    }
}
