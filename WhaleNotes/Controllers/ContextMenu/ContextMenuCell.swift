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
            iconView.image = UIImage(systemName: menuItem.icon, pointSize: 16, weight: .regular)
//            if menuItem.isDestructive {
//                iconView.tintColor = .red
//                labelView.textColor = .red
//            }else {
//                iconView.tintColor = UIColor.init(hexString: "#444444")
//                labelView.textColor = .primaryText
//            }
            arrowView.isHidden = !menuItem.isNeedJump
        }
    }
    
    static let padding:CGFloat = 12
    static let spacing:CGFloat = 10
    static let cellHeight: CGFloat = 46
    
    private static let labelTextFont = UIFont.systemFont(ofSize: 16)
    
    private lazy var labelView: UILabel = UILabel().then {
        $0.textColor = .popMenuText
        $0.font = ContextMenuCell.labelTextFont
    }
    
    private lazy var iconView: UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.tintColor = .popMenuIconTint
    }
    
    private lazy var arrowView: UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.image = UIImage(systemName: "chevron.right", pointSize: 12, weight: .regular)
        $0.tintColor = .popMenuText
        $0.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        self.backgroundColor = .clear
        
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(32)
            make.leading.equalToSuperview().offset(ContextMenuCell.padding)
        }
        
        let spacing:CGFloat = 10
        
        contentView.addSubview(labelView)
        contentView.addSubview(arrowView)
        labelView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(spacing)
            make.trailing.equalTo(arrowView.snp.leading).offset(-spacing)
        }
        
        arrowView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-ContextMenuCell.padding)
        }
        
    }
    
    
    static func caculateTextWidth(text: String) -> CGFloat {
        let size = text.size(withAttributes:[.font: ContextMenuCell.labelTextFont])
        return size.width + 58 + 20
    }
    
}

