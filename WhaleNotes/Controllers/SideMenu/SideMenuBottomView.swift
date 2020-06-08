//
//  SideMenuBottomView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class SideMenuBottomView: UIView {
    
    var callbackNewBlock:(()->Void)?
    
    private lazy var newBlockBtn: UIButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        $0.tintColor =  UIColor.init(hexString: "#666666")
        $0.setTitleColor(UIColor.init(hexString: "#666666"), for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.setImage(image, for: .normal)
        $0.setImageTitleSpace(5)
        $0.setTitle("添加便签板", for: .normal)
        $0.addTarget(self, action: #selector(self.newBlockBtnTapped), for: .touchUpInside)
    }
    
    private lazy var settingBlockBtn: UIButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let image = UIImage(systemName: "slider.horizontal.3", withConfiguration: config)
        $0.tintColor =  UIColor.init(hexString: "#666666")
        $0.setImage(image, for: .normal)
    }
    
    private lazy var divider:UIView = UIView().then {
        $0.backgroundColor =  UIColor.init(hexString: "#f1f1f1")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        
        self.addSubview(newBlockBtn)
        newBlockBtn.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(24)
        }
        
        self.addSubview(settingBlockBtn)
        settingBlockBtn.snp.makeConstraints { (make) in
            make.height.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.addSubview(divider)
        divider.snp.makeConstraints { (make) in
            make.height.equalTo(1)
            make.width.equalToSuperview()
            make.top.equalTo(self.snp.top)
        }
        
    }
}

extension SideMenuBottomView {
    @objc func newBlockBtnTapped() {
        callbackNewBlock?()
    }
}
