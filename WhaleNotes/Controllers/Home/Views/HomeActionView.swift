//
//  HomeActionView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/9.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class HomeActionView:UIView {
    
    private  let arrowWidth:CGFloat = 12
    private  let arrowSpacing:CGFloat = 16
    
    
    var callbackTapped:(()->Void)?
    
    
    enum SizeConstants {
        static let height:CGFloat = 48
        static let menuButtonWidth:CGFloat = 54
        static let adButtonWidth:CGFloat = 100
    }
    
    lazy var noteButton = UIButton().then {
        
        let spacing:CGFloat = 3
        
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 16,weight: .regular)
        $0.setTitle("笔记", for: .normal)
        $0.tintColor = UIColor(hexString: "#FFFFFF")
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        $0.setImage(UIImage(systemName: "plus",pointSize: 16), for: .normal)
        $0.setImageTitleSpace(8)
    }
    
    
    lazy var menuButton = UIButton().then {
        let spacing:CGFloat = 3
        $0.tintColor = UIColor(hexString: "#FFFFFF")
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        $0.setImage(UIImage(systemName: "ellipsis",pointSize: 16), for: .normal)
    }
    
    
    private lazy var dividerView = UIView().then {
        let spacing:CGFloat = 3
        $0.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)
    }
    
    
     override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
     }
    
    private func setupUI() {
        
        self.layer.cornerRadius = SizeConstants.height / 2
        self.backgroundColor = .iconColor
            
        self.addSubview(noteButton)
        self.addSubview(menuButton)
        
        noteButton.snp.makeConstraints {
            $0.width.equalTo(SizeConstants.adButtonWidth)
            $0.leading.equalToSuperview()
            $0.trailing.equalTo(menuButton.snp.leading)
            $0.height.equalToSuperview()
        }
        
        menuButton.snp.makeConstraints {
            $0.width.equalTo(SizeConstants.menuButtonWidth)
            $0.leading.equalTo(noteButton.snp.trailing)
            $0.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        
        self.addSubview(dividerView)
        dividerView.snp.makeConstraints {
            $0.width.equalTo(0.5)
            $0.top.equalToSuperview().offset(14)
            $0.bottom.equalToSuperview().offset(-14)
            $0.leading.equalTo(noteButton.snp.trailing)
        }
        
    }
    
    @objc func buttonTapped() {
    }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
     }
}
