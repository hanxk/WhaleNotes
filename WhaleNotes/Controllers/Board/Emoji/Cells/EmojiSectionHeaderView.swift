//
//  EmojiSectionHeaderView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class EmojiSectionHeaderView: UICollectionReusableView {
    
    var categoryEmoji:CategoryAndEmoji! {
        didSet {
            self.label.text = categoryEmoji.category.text
        }
    }
    
    private lazy var label:UILabel = UILabel().then {
        $0.textColor = UIColor.init(hexString: "#666666")
        $0.font = UIFont.systemFont(ofSize: 14)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(15)
            $0.bottom.equalToSuperview().offset(-12)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
