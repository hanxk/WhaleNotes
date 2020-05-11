//
//  ContextMenuCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/11.
//  Copyright © 2020 hanxk. All rights reserved.
//


import UIKit
import SnapKit

class ContextMenuCell: UITableViewCell {
    
    var menuItem: ContextMenuItem! {
        didSet {
            labelView.text = menuItem.label
            iconView.image = UIImage(systemName: menuItem.icon)
        }
    }
    
    private static let labelTextFont = UIFont.systemFont(ofSize: 15)
    
    private lazy var labelView: UILabel = UILabel().then {
        $0.textColor = .primaryText
        $0.font = ContextMenuCell.labelTextFont
    }
    
    private lazy var iconView: UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.tintColor = .primaryText
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        self.selectionStyle = .none
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.width.equalTo(26)
            make.leading.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview()
        }
        
        contentView.addSubview(labelView)
        labelView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-16)
        }
    }
    
    
    static func caculateTextWidth(text: String) -> CGFloat {
        let size = text.size(withAttributes:[.font: ContextMenuCell.labelTextFont])
        return size.width + 58 + 14
    }
    
}

