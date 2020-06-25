//
//  BoardSettingButtonCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BoardSettingButtonCell: UITableViewCell {
    
    private lazy var label = UILabel().then {
        $0.textColor = .red
        $0.font = UIFont.systemFont(ofSize: 16)
    }
    
    var lblText:String = "" {
        didSet {
            self.label.text = lblText
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        self.contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
    }
    
}
