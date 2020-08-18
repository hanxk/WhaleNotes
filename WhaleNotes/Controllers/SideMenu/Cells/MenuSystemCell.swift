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
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            iconImageView.image = UIImage(systemName: self.menuSysItem.icon, withConfiguration: config)
            iconImageView.tintColor = UIColor.init(hexString: "#666666")
            titleLabel.text = self.menuSysItem.title
        }
    }
    private lazy var cellBgView = SideMenuViewController.generateCellSelectedView()
    
    
    var cellIsSelected:Bool = false {
        didSet {
            self.cellBgView.isHidden = !cellIsSelected
        }
    }
    
    private lazy var iconImageView:UIImageView = UIImageView().then {
        $0.contentMode = .center
    }
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .sidemenuText
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
            $0.height.equalToSuperview()
            $0.leading.equalToSuperview().offset(SideMenuCellContants.selectedPadding)
            $0.trailing.equalToSuperview().offset(-SideMenuCellContants.selectedPadding)
        }
        
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(SideMenuCellContants.iconWidth)
            make.leading.equalToSuperview().offset(SideMenuCellContants.cellPadding)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-SideMenuCellContants.cellPadding)
            make.centerY.equalToSuperview()
        }
        
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.backgroundColor = SideMenuCellContants.highlightColor
//    }
//    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.backgroundColor = .clear
//    }
//    
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.backgroundColor = .clear
//    }
}
