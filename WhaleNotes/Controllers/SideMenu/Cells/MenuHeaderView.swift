//
//  MenuHeaderView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class MenuHeaderView: UIView {
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        $0.textColor = UIColor.init(hexString: "#888")
        $0.text = "小鲸鱼"
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setupUI()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        
    }
}
