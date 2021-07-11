//
//  BoardTagCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class BoardTagCell: UICollectionViewCell {
    
    static let horizontalPadding:CGFloat = 8
    static let cellHeight:CGFloat = 24
    static let iconTextSpacing:CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView  = UIImageView().then {
        $0.clipsToBounds = true
//        $0.layer.cornerRadius = AttachmentsConstants.radius
        $0.backgroundColor = .placeHolderColor
    }
    
    private lazy var tagView = UIView().then {
        $0.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.08)
        $0.layer.cornerRadius = BoardTagCell.cellHeight / 2
    }
    
    private lazy var emojiLabel:UILabel = UILabel().then{
        $0.font =  UIFont.systemFont(ofSize: 12, weight: .light)
        $0.textAlignment = .center
    }
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        $0.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        $0.textAlignment = .left
    }
    
    var board:Board! {
        didSet {
            emojiLabel.text = board.icon
            titleLabel.text = board.title
        }
    }
    
    private func setupUI() {
       
        contentView.addSubview(tagView)
        tagView.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.centerY.equalToSuperview()
            $0.height.equalTo(BoardTagCell.cellHeight)
        }
        
        tagView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(BoardTagCell.horizontalPadding)
            $0.centerY.equalToSuperview()
        }
        
        tagView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(BoardTagCell.iconTextSpacing)
            $0.trailing.equalToSuperview().offset(-BoardTagCell.horizontalPadding)
            $0.centerY.equalToSuperview()
        }
    }
    
    @objc func handleButtonTapped() {
        
    }
    
    static func sizeOfString (string: String,font:UIFont) -> CGSize {
        let attributes = [NSAttributedString.Key.font:font]
        let attString = NSAttributedString(string: string,attributes: attributes as [NSAttributedString.Key : Any])
        let framesetter = CTFramesetterCreateWithAttributedString(attString)
        return CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0,length: 0), nil, CGSize(width: Double.greatestFiniteMagnitude, height: Double.greatestFiniteMagnitude), nil)
    }
    
    static func cellWidth(board:Board) ->CGFloat {
        let text = board.icon + board.title
        let width = text.width(withHeight:CGFloat.greatestFiniteMagnitude, font:  UIFont.systemFont(ofSize: 13))
        return horizontalPadding * 2 + iconTextSpacing + width
    }
    
}
