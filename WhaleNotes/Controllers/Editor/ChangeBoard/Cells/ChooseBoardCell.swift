//
//  BoardCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
class ChooseBoardCell: UITableViewCell {
    
    var board:Board! {
        didSet {
            emojiLabel.text = board.icon
            titleLabel.text = board.title
        }
    }
    
    var isChoosed:Bool = false {
        didSet {
            self.checkImageView.isHidden = !isChoosed
        }
    }
    
    
    private lazy var emojiLabel:UILabel = UILabel().then{
        $0.font = UIFont.systemFont(ofSize: 17)
        $0.textAlignment = .center
    }
    
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .primaryText
        $0.textAlignment = .left
    }
    
    private lazy var checkImageView: UIImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark", pointSize: 15, weight: .regular)
        $0.isHidden = true
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundColor = .white
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints {
            $0.width.height.equalTo(24)
            $0.leading.equalToSuperview().offset(ContextMenuCell.padding)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkImageView)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(ContextMenuCell.spacing)
            $0.trailing.equalToSuperview().offset(-40)
            $0.centerY.equalToSuperview()
        }
        
        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        
        
    }
}
