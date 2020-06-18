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
            arrowView.isHidden = !menuItem.isNeedJump
        }
    }
    

    
    static let padding:CGFloat = 10
    static let cellHeight: CGFloat = 48
    
    private static let labelTextFont = UIFont.systemFont(ofSize: 15)
    
    private lazy var labelView: UILabel = UILabel().then {
        $0.textColor = .primaryText
        $0.font = ContextMenuCell.labelTextFont
    }
    
    private lazy var iconView: UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.tintColor = UIColor.init(hexString: "#444444")
    }
    
    private lazy var arrowView: UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.image = UIImage(systemName: "chevron.right", pointSize: 12, weight: .light)
        $0.tintColor = UIColor.init(hexString: "#999999")
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
        
        
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            
            make.width.equalTo(26)
            make.height.equalToSuperview()
            make.leading.equalToSuperview().offset(NoteDetailMenuCell.padding)
        }
        
        contentView.addSubview(labelView)
        contentView.addSubview(arrowView)
        labelView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.trailing.equalTo(arrowView.snp.leading).offset(-8)
        }
        
        
        arrowView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
//            make.leading.equalTo(labelView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-NoteDetailMenuCell.padding)
        }
//        contentView.addSubview(labelView)
//        labelView.snp.makeConstraints { (make) in
//            make.leading.equalToSuperview().offset(ContextMenuCell.padding)
//            make.top.bottom.equalToSuperview()
//            make.top.bottom.equalToSuperview()
//        }
//
//        contentView.addSubview(iconView)
//        iconView.snp.makeConstraints { (make) in
//            make.width.equalTo(26)
//            make.height.equalToSuperview()
//            make.trailing.equalToSuperview().offset(-ContextMenuCell.padding)
//        }
        
    }
    
    
    static func caculateTextWidth(text: String) -> CGFloat {
        let size = text.size(withAttributes:[.font: ContextMenuCell.labelTextFont])
        return size.width + 58 + 20
    }
    
}

