//
//  MenuCategoryCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
class MenuCategoryCell: UITableViewCell {
    
    var boardCategory:BoardCategory! {
        didSet {
            titleLabel.text = boardCategory.title
            arrowImageView.image = boardCategory.isExpand ? arrowDownImage : arrowRightImage
        }
    }
    var callbackMenuTapped:((UIView, BoardCategory)->Void)?
    private lazy var cellBgView = SideMenuViewController.generateCellSelectedView()
    
    private lazy var arrowDownImage:UIImage = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        var image = UIImage(systemName: "chevron.down", withConfiguration: config)
        return image!
    }()
    
    private lazy var arrowRightImage:UIImage = {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .light)
        var image = UIImage(systemName: "chevron.right", withConfiguration: config)
        return image!
    }()
    
    
    private lazy var arrowImageView:UIImageView = UIImageView().then {
        $0.tintColor = UIColor(hexString: "#666666")
        $0.contentMode = .center
    }
    
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .primaryText
        $0.textAlignment = .left
    }
    
    
    private lazy var menuButton: UIButton = UIButton().then {
         $0.contentMode = .center
         $0.imageView?.contentMode = .scaleAspectFit
         $0.tintColor  = .thirdColor
         let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
         $0.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
         $0.addTarget(self, action: #selector(self.menuButtonTapped), for: .touchUpInside)
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
        
        contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints {
            $0.width.height.equalTo(SideMenuCellContants.iconWidth)
            $0.leading.equalToSuperview().offset(20)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(menuButton)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(arrowImageView.snp.trailing).offset(14)
            $0.trailing.equalTo(menuButton.snp.leading).offset(5)
            $0.centerY.equalToSuperview()
        }
        
        menuButton.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.width.equalTo(32)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        
    }
    
    @objc func menuButtonTapped() {
        self.callbackMenuTapped?(menuButton,self.boardCategory)
    }
}
