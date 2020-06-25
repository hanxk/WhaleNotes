//
//  BoardIconView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BoardIconView: UITableViewHeaderFooterView {
    
    static let cellHeight:CGFloat = 106
    var callbackTapped:(()->Void)?
    
    private lazy var iconButton = UIButton().then {
        $0.backgroundColor = UIColor.white
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor(hexString: "#E5E5E5").cgColor
        $0.layer.cornerRadius = 8
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
        iconButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.width.height.equalTo(80)
        }
        
    }
}
