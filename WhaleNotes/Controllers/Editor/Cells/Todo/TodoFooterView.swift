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
        $0.setTitle("新建清单项", for: .normal)
        
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        $0.setTitleColor(UIColor(hexString: "#858687"), for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        $0.tintColor = .thirdColor
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        var image = UIImage(systemName: "plus", withConfiguration: config)
        $0.setImage(image, for: .normal)
        
        let imageTitlePadding:CGFloat = 10
          $0.titleEdgeInsets = UIEdgeInsets(
              top: 0,
              left: imageTitlePadding,
              bottom: 0,
              right: -imageTitlePadding
          )
        
        $0.addTarget(self, action: #selector(self.handleAddButtonTapped), for: .touchUpInside)

        
    }
    private lazy var menuButton: UIButton = UIButton().then {
         $0.contentMode = .center
         $0.imageView?.contentMode = .scaleAspectFit
         $0.tintColor  = .thirdColor
         let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .light)
         $0.setImage(UIImage(systemName: "ellipsis", withConfiguration: config), for: .normal)
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        $0.addTarget(self, action: #selector(self.handleMenuButtonTapped), for: .touchUpInside)
     }
    
    
    var addButtonTapped:(() ->Void)?
    var menuButtonTapped:((UIButton) ->Void)?

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.setup()
    }
    
    private func setup() {
        self.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }
        
        
//        self.addSubview(menuButton)
//        menuButton.snp.makeConstraints { (make) in
//            make.height.equalToSuperview()
//            make.trailing.equalToSuperview()
//        }
    }
    @objc private func handleAddButtonTapped() {
        self.addButtonTapped?()
    }
    
    
    @objc private func handleMenuButtonTapped(sender:UIButton) {
        self.menuButtonTapped?(sender)
    }
    
    
}
