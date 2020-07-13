//
//  MenuBoardCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
class MenuBoardCell: UITableViewCell {
    
    var board:Block! {
        didSet {
            if let properties = board.blockBoardProperties {
                emojiLabel.text = properties.icon
                titleLabel.text = properties.title
            }
        }
    }
    
    var cellIsSelected:Bool = false {
        didSet {
            self.cellBgView.isHidden = !cellIsSelected
        }
    }
    
    private lazy var cellBgView = SideMenuViewController.generateCellSelectedView()
    
    private lazy var emojiLabel:UILabel = UILabel().then{
        $0.font = UIFont.systemFont(ofSize: 22)
        $0.textAlignment = .center
    }
    
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .sidemenuText
        $0.textAlignment = .left
    }
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        contentView.addSubview(cellBgView)
        cellBgView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
        
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints {
            $0.width.height.equalTo(SideMenuCellContants.iconWidth)
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(14)
            $0.trailing.equalToSuperview().offset(-20)
            $0.centerY.equalToSuperview()
        }
    }
}
