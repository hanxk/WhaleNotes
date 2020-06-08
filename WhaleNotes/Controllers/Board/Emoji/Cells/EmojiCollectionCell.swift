//
//  EmojiCollectionCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/7.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class EmojiCollectionCell:UICollectionViewCell {
    var emoji:Emoji! {
        didSet {
            emojiButton.text = emoji.value
        }
    }
    private lazy var emojiButton:UILabel = UILabel().then {
        $0.font = UIFont.init(name: "AppleColorEmoji", size: 32)
        $0.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(emojiButton)
        emojiButton.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
