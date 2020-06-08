//
//  MenuCategoryCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
class MenuCategoryCell: UITableViewCell {
    
    var menuSysItem:MenuSystemItem!
    
    private lazy var iconImageView:UIImageView = UIImageView().then{
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        $0.image = UIImage(systemName: self.menuSysItem.icon, withConfiguration: config)
    }
    
  
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 26, weight: .regular)
        $0.textColor = .primaryText
        $0.text = self.menuSysItem.title
    }
    
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.leading.equalToSuperview().offset(20)
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
