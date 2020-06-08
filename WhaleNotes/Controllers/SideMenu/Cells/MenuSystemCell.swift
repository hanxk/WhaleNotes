//
//  MunuSystemCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class MenuSystemCell: UITableViewCell {
    
    var menuSysItem:MenuSystemItem!{
        didSet {
            let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
            iconImageView.image = UIImage(systemName: self.menuSysItem.icon, withConfiguration: config)
            iconImageView.tintColor = UIColor.init(hexString: "#828282")
            titleLabel.text = self.menuSysItem.title
        }
    }
    
    private lazy var iconImageView:UIImageView = UIImageView().then {
        $0.contentMode = .center
    }
  
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        $0.textColor = UIColor.init(hexString: "#444444")
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
        
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImageView.snp.trailing).offset(14)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }
        self.selectionStyle = .none
    }
}
