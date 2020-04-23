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
    private lazy var addButton: UIButton = UIButton().then {
        $0.setImage(UIImage(systemName: "plus.circle",withConfiguration: config), for: .normal)
    }
    lazy var moreButton: UIButton = UIButton().then {
        $0.setImage(UIImage(systemName: "ellipsis",withConfiguration: config), for: .normal)
    }
    
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
            make.leading.equalTo(self).offset(14)
            make.centerY.equalToSuperview()
        }
        
        moreButton.snp.makeConstraints { (make) in
            make.trailing.equalTo(self).offset(-14)
            make.centerY.equalToSuperview()
        }
        tintColor = .buttonTintColor
        
        self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
        self.layer.shadowOpacity = 1
        self.layer.shadowRadius = 2
        self.layer.shadowOffset = CGSize(width: 0, height: -1)
        self.layer.masksToBounds = false

    }
}
