//
//  TodoFooterView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/4.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class TodoFooterView: UIView {
    
    private lazy var addButton: UIButton = UIButton().then {
        $0.setTitle("添加清单项", for: .normal)
        $0.setTitleColor(UIColor(hexString: "#858687"), for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.tintColor = .thirdColor
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        var image = UIImage(systemName: "plus", withConfiguration: config)
        $0.setImage(image, for: .normal)
        
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)
        
        let imageTitlePadding:CGFloat = 10
        $0.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
    
    
    
    var addButtonTapped:(() ->Void)?

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setup()
        self.backgroundColor = .white
    }
    
    private func setup() {
        self.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
    }
    @objc private func handleAddButtonTapped() {
        self.addButtonTapped?()
    }
}
