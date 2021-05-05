//
//  MunuSystemCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class SideMenuCell: UITableViewCell {
  
    private lazy var cellBgView = SideMenuViewController.generateCellSelectedView()
    
    private  let arrowButtonWidth = 36
    private  let arrowButtonSpace = 0
    
    let iconSize:CGFloat = 18
    
    var arrowButtonTapAction:(() -> Void)?
    
    var cellIsSelected:Bool = false {
        didSet {
            self.cellBgView.isHidden = !cellIsSelected
            
            iconImageView.tintColor = self.cellIsSelected ? .sidemenuSelectedTint : UIColor(hexString: "#6F6F6F")
            
            let weight:UIFont.Weight = self.cellIsSelected ? .medium : .regular
            titleLabel.font = UIFont.systemFont(ofSize: 17, weight: weight)
            titleLabel.textColor = self.cellIsSelected ? .sidemenuSelectedTint : .sidemenuText
        }
    }
    
    private lazy var iconImageView:UIImageView = UIImageView().then {
        $0.contentMode = .center
    }
    
    private lazy var titleLabel: UILabel = UILabel()
    
    
    private lazy var arrowButton:UIButton = UIButton().then {
//        let img = UIImage(systemName: "chevron.right",pointSize: 14)?.withRenderingMode(.alwaysTemplate)
//        $0.setImage(img, for: .normal)
        $0.tintColor = UIColor(hexString: "#6F6F6F")
        $0.addTarget(self, action: #selector(arrowButtonTapped), for: .touchUpInside)
//        $0.backgroundColor = .red
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        self.backgroundColor = .sidemenuBg
        self.selectionStyle = .none
        
        contentView.addSubview(cellBgView)
        cellBgView.snp.makeConstraints {
            $0.height.equalToSuperview()
//            $0.width.equalToSuperview()
            $0.leading.equalToSuperview().offset(SideMenuCellContants.selectedPadding)
            $0.trailing.equalToSuperview().offset(-SideMenuCellContants.selectedPadding)
        }
        
        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(SideMenuCellContants.iconWidth)
            make.leading.equalToSuperview().offset(paddingL2)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowButton)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconImageView.snp.trailing).offset(SideMenuCellContants.titlePaddingRight)
            make.trailing.equalTo(arrowButton.snp.leading)
            make.centerY.equalToSuperview()
        }
        
        arrowButton.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-SideMenuCellContants.selectedPadding)
            make.height.equalToSuperview()
            make.width.equalTo(arrowButtonWidth)
        }
        
    }
    
    
    func bindSysMenuItem(_ sysItem:SystemMenuItem) {
        bindIconAndTitle(icon:UIImage(systemName: sysItem.icon,pointSize: iconSize)!, title: sysItem.title)
    }
    
    
    func bindTag(_ tag:Tag,childCount:Int,isExpand:Bool)  {
        let icon = tag.icon.isEmpty ? UIImage(systemName: ConstantsUI.tagDefaultImageName, pointSize: iconSize)?.withRenderingMode(.alwaysTemplate) : tag.icon.emojiToImage(fontSize: iconSize)
        bindIconAndTitle(icon:icon!, title: tag.title,childCount:childCount)
        
        self.isExpand = isExpand
        let image = UIImage(systemName: isExpand ? "chevron.down" : "chevron.right",pointSize: 14)?.withRenderingMode(.alwaysTemplate)
        self.arrowButton.setImage(image, for: .normal)
    }
    private var isExpand = false
    private var paddingL2:Int =  SideMenuCellContants.cellPadding
    
    private func bindIconAndTitle(icon:UIImage,title:String,childCount:Int = 0)  {
        self.iconImageView.image = icon
        let titles = title.split("/")
        self.bindTitle(titles: titles)
        self.arrowButton.isHidden = childCount == 0
//        self.setupTitleTrailing(childCount: childCount)
    }
    
    
    private func bindTitle(titles:[String]){
        let shortTitle  = titles[titles.count-1]
        self.titleLabel.text =  shortTitle
        let paddingL = titles.count * SideMenuCellContants.cellPadding
        if paddingL2 == paddingL {
            return
        }
        paddingL2  =  paddingL
        iconImageView.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(paddingL)
        }
    }
    
    var titleTrailing:Int =  SideMenuCellContants.cellPadding + SideMenuCellContants.titlePaddingRight
    private func setupTitleTrailing(childCount:Int){
        
        self.arrowButton.isHidden = childCount == 0
        let newTrailing =  childCount > 0 ?  arrowButtonWidth + arrowButtonSpace + SideMenuCellContants.selectedPadding  :  SideMenuCellContants.cellPadding+SideMenuCellContants.titlePaddingRight
        if titleTrailing  ==  newTrailing{
            return
        }
        titleTrailing = newTrailing
        titleLabel.snp.updateConstraints {
            $0.trailing.equalToSuperview().offset(-newTrailing)
        }
    }
    
    @objc func arrowButtonTapped() {
        arrowButtonTapAction?()
    }
}
