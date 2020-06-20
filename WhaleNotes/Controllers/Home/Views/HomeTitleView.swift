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
    
    private lazy var button = UIButton().then {
        
        let spacing:CGFloat = 3
        
        $0.setTitleColor(.primaryText, for: .normal)
        $0.titleLabel?.font = UIFont.systemFont(ofSize: 15,weight: .medium)
        $0.setImageTitleSpace(3)
        
        $0.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4 + arrowWidth)
        $0.tintColor = UIColor(hexString: "#666666")
//        $0.backgroundColor = .blue
    }
    
    private let arrowImageView = UIImageView().then {
        $0.image =  UIImage(systemName: "chevron.down", pointSize: 13, weight: .light)?.withRenderingMode(.alwaysTemplate)
        $0.tintColor  = UIColor.primaryText.withAlphaComponent(0.8)
//        $0.backgroundColor = .red
    }
    
//    var title:String = "" {
//        didSet {
//            button.setTitle(title, for: .normal)
//        }
//    }
    
    func setTitle(_ title:String,icon:UIImage? = nil) {
        button.setTitle(title, for: .normal)
        button.setImage(icon?.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    
    func setTitle(_ title:String,emoji:String) {
        guard let emojiImage = emoji.emojiToImage(fontSize: 15) else { return }
       
        button.setTitle(title, for: .normal)
        button.setImage(emojiImage, for: .normal)
    }
//
//    func setTitle(title:String) {
//        button.setTitle(title, for: .normal)
//        button.setImage(nil, for: .normal)
//    }
    
    
     override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
     }
    
    private func setupUI() {
        self.addSubview(button)
        self.addSubview(arrowImageView)
        
        button.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
//            $0.trailing.lessThanOrEqualTo(arrowImageView.snp.leading)
            $0.height.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.width.equalTo(arrowWidth)
            $0.centerY.equalToSuperview()
        }
    }

     required init?(coder aDecoder: NSCoder) {
         super.init(coder: aDecoder)
     }
}
