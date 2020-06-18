//
//  NoteDetailMenuCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/17.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit

class NoteDetailMenuCell: UITableViewCell {
    
    var menuItem: ContextMenuItem! {
        didSet {
            labelView.text = menuItem.label
            iconView.image = UIImage(systemName: menuItem.icon)
        }
    }
    static let padding:CGFloat = 10
    
    private static let labelTextFont = UIFont.systemFont(ofSize: 15)
    
    private lazy var labelView: UILabel = UILabel().then {
        $0.textColor = .primaryText
        $0.font = NoteDetailMenuCell.labelTextFont
    }
    
    private lazy var iconView: UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.tintColor = UIColor.init(hexString: "#444444")
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
        labelView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-NoteDetailMenuCell.padding)
        }
        
        
    }
    
    
    static func caculateTextWidth(text: String) -> CGFloat {
        let size = text.size(withAttributes:[.font: NoteDetailMenuCell.labelTextFont])
        return size.width + 58 + 20
    }
    
}

