//
//  BoardIconView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BoardIconView: UITableViewHeaderFooterView {
    
    static let cellHeight:CGFloat = 154
    var callbackTapped:(()->Void)?
    
    private lazy var iconButton = UIButton().then {
        $0.backgroundColor = UIColor.white
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(hexString: "#DDDDDD").cgColor
        $0.layer.cornerRadius = 10
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    private lazy var changeButton = UIButton().then {
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 13,weight: .medium)
        $0.setTitle("更换图标", for: .normal)
        $0.setTitleColor(.brand, for: .normal)
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    var board:Board! {
        didSet {
            let fontSize:CGFloat = 60
            if board.type == BoardType.user.rawValue {
                iconButton.setImage(board.icon.emojiToImage(fontSize: fontSize), for: .normal)
            }else {
                iconButton.setImage(UIImage(systemName: board.icon, pointSize: fontSize, weight: .light), for: .normal)
            }
        }
    }
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc func buttonTapped() {
        self.callbackTapped?()
    }
    
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        self.addSubview(iconButton)
        
        self.addSubview(changeButton)
        changeButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-14)
            $0.width.equalTo(iconButton.snp.width)
            $0.height.equalTo(32)
        }
        
        iconButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.height.equalTo(80)
            $0.bottom.equalTo(changeButton.snp.top).offset(-4)
        }
        
    }
}
