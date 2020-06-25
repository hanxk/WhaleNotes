//
//  BoardSettingItemCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BoardSettingItemCell: UITableViewCell {
    
    
    lazy var titleLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .primaryText
    }
    
    lazy var valueLabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = UIColor.init(hexString: "#333333")
    }
    
    var titleAndValue:(String,String)! {
        didSet {
            titleLabel.text = titleAndValue.0
            valueLabel.text = titleAndValue.1
        }
    }
    
    private lazy var arrowImageView = UIImageView().then {
        $0.image = UIImage(systemName: "chevron.right", pointSize: 15, weight: .light)
        $0.tintColor = UIColor.black.withAlphaComponent(0.4)
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        let horizontalPadding:CGFloat = 14
        let spacing:CGFloat = 6
        
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(horizontalPadding)
            $0.centerY.equalToSuperview()
        }
        
        
        self.contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-horizontalPadding)
            $0.centerY.equalToSuperview()
        }
        
        self.contentView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints {
            $0.trailing.equalTo(arrowImageView.snp.leading).offset(-spacing)
            $0.centerY.equalToSuperview()
        }
        
        
    }
    
}
