//
//  BoardAvatarCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/23.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class BoardIconCell: UITableViewCell {
    
    static let cellHeight:CGFloat = 80
    
    private lazy var iconButton = UIButton().then {
        $0.backgroundColor = UIColor.init(hexString: "#F6F6F6")
        $0.layer.borderWidth = 0.5
        $0.layer.borderColor = UIColor.dividerGray.cgColor
        $0.layer.cornerRadius = 8
    }
    
    var iconImage:UIImage! {
        didSet {
            iconButton.setImage(iconImage, for: .normal)
        }
    }
    
    var board:Board! {
        didSet {
            let fontSize:CGFloat = 60
            if board.type == BoardType.user.rawValue {
                iconButton.setImage(board.icon.emojiToImage(fontSize: fontSize), for: .normal)
            }else {
                iconButton.setImage(UIImage(systemName: board.icon, pointSize: fontSize, weight: .light), for: .normal)
            }
        }
    }
    

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    
    private func setup() {
        self.backgroundColor = .clear
        self.contentView.addSubview(iconButton)
        iconButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(BoardIconCell.cellHeight)
        }
        
    }
    
}
