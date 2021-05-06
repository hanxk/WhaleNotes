//
//  HomeTitleView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class HomeTitleView:UIView {
    
    private  let arrowWidth:CGFloat = 12
    private  let arrowSpacing:CGFloat = 16
    
    
    var callbackTapped:(()->Void)?
    
    private lazy var button = UIButton().then {
        
        let spacing:CGFloat = 3
        
        $0.setTitleColor(.primaryText, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 18,weight: .medium)
        $0.setImageTitleSpace(3)
        
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: arrowSpacing)
        $0.tintColor = UIColor(hexString: "#666666")
        $0.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    var isEnabled:Bool = true {
        didSet {
            button.isEnabled = isEnabled
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: (isEnabled ? arrowSpacing : 0))
            arrowImageView.isHidden = !isEnabled
        }
    }
    
    private let arrowImageView = UIImageView().then {
        $0.image =  UIImage(systemName: "chevron.down", pointSize: 13, weight: .regular)?.withRenderingMode(.alwaysTemplate)
        $0.tintColor  = UIColor.primaryText.withAlphaComponent(0.8)
    }
    
    func setTitle(_ title:String,icon:UIImage? = nil) {
        button.setTitle(title, for: .normal)
        button.setImage(icon?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    
    func setTitle(_ title:String,emoji:String) {
        button.setImage(emoji.emojiToImage(fontSize: 18), for: .normal)
        button.setTitle(title, for: .normal)
    }
    
     override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
     }
    
    private func setupUI() {
        self.addSubview(button)
        
        button.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.height.equalToSuperview()
        }
        
        self.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.equalTo(arrowWidth)
            $0.centerY.equalToSuperview()
        }
    }
    
    @objc func buttonTapped() {
        if isEnabled {
            callbackTapped?()
        }
    }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
     }
}
