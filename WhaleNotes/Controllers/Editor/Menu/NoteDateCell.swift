//
//  NoteDateCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class NoteDateCell: UITableViewCell {
    
    static let padding:CGFloat = 10
    
    var dateInfo:(String,String) = ("","") {
        didSet {
            titleLabel.text = dateInfo.0
            dateLabel.text = dateInfo.1
        }
    }
    
    
    private lazy var titleLabel = UILabel().then {
               $0.font = UIFont.systemFont(ofSize: 13)
               $0.textColor = UIColor.init(hexString: "#666666")
           }
    
    private lazy var dateLabel = UILabel().then {
               $0.font = UIFont.systemFont(ofSize: 14)
               $0.textColor = UIColor.init(hexString: "#333333")
           }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        let spacing = 8
        let vPadding = 12
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(ContextMenuCell.padding)
            $0.top.equalToSuperview().offset(vPadding)
        }
        self.contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.leading)
            $0.top.equalTo(titleLabel.snp.bottom).offset(spacing)
            $0.bottom.equalToSuperview().offset(-vPadding)
        }
        
    }
    
    
}

