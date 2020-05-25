//
//  BottomBarView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/21.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit

class BottomBarView: UIView {
    
    let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .light)
    lazy var addButton: UIButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus.circle",withConfiguration: config), for: .normal)
    }
    
    lazy var moreButton: UIButton = UIButton().then {
        $0.setImage(keyboardImage, for: .normal)
        $0.isHidden = true
    }
    
    var keyboardShow = false {
        didSet {
            moreButton.isHidden = !keyboardShow
//            moreButton.setImage(keyboardShow ? keyboardImage : moreImage, for: .normal)
        }
    }
    
    private lazy var moreImage = UIImage(systemName: "ellipsis",withConfiguration: config)
    private lazy var keyboardImage = UIImage(systemName: "keyboard.chevron.compact.down",withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .light))
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addButton)
        addSubview(moreButton)
        
        self.backgroundColor = .white
        
        addButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.leading.equalToSuperview().offset(3)
            make.centerY.equalToSuperview()
        }
        
        moreButton.snp.makeConstraints { (make) in
            make.width.equalTo(44)
            make.trailing.equalToSuperview().offset(-5)
            make.top.bottom.equalToSuperview()
        }
        tintColor = .buttonTintColor
        
//        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
//        self.layer.shadowOpacity = 1
//        self.layer.shadowRadius = 2
//        self.layer.shadowOffset = CGSize(width: 0, height: -1)
//        self.layer.masksToBounds = false

    }
}
