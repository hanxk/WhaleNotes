//
//  BoardSettingItemView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BoardSettingItemView: TappedView {
    
    var callbackViewTapped:(()->Void)?
    
    private lazy var titleButton: UIButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        let image = UIImage(systemName: "folder.fill", withConfiguration: config)
        $0.tintColor =  UIColor.init(hexString: "#999999")
        $0.setTitleColor(.primaryText, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.setImage(image, for: .normal)
        $0.setImageTitleSpace(10)
        $0.setTitle("分类", for: .normal)
    }
    
    private lazy var arrowImageView: UIImageView = UIImageView().then {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = UIImage(systemName: "chevron.right", withConfiguration: config)
        $0.image = image
        $0.tintColor =  UIColor.init(hexString: "#999")
    }
    
    private lazy var valueLabel: IconLabel = IconLabel().then {
        $0.text = "无分类"
        $0.textColor = UIColor.init(hexString: "#666")
        $0.font = UIFont.systemFont(ofSize: 14)
    }
    
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(titleButton)
        titleButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        self.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        
        self.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-6)
        }
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.viewTapped(gesture:))))
    }
}

extension BoardSettingItemView {
    @objc func viewTapped(gesture:UITapGestureRecognizer) {
        callbackViewTapped?()
    }
}
