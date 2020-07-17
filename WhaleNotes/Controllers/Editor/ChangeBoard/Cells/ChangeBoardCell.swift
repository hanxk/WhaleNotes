//
//  ChangeBoardCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/20.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
class ChangeBoardCell: UITableViewCell {
    
    var board:BlockInfo! {
        didSet {
            let fontSize:CGFloat = 20
            let boardProperties = board.blockBoardProperties!
            if boardProperties.type == .user {
                emojiLabel.image = boardProperties.icon.emojiToImage(fontSize: fontSize)
            }else {
                emojiLabel.image = UIImage(systemName: boardProperties.icon, pointSize: fontSize, weight: .light)
            }
            titleLabel.text = boardProperties.title
        }
    }
    
    var isChoosed:Bool = false {
        didSet {
            self.checkImageView.isHidden = !isChoosed
        }
    }
    
    
    private lazy var emojiLabel:UIImageView = UIImageView().then {
        $0.contentMode = .center
        $0.tintColor = UIColor(hexString: "#666666")
    }
    
    
    private lazy var titleLabel: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .primaryText
        $0.textAlignment = .left
    }
    
    
    private lazy var checkImageView: UIImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark", pointSize: 15, weight: .regular)
        $0.isHidden = true
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundColor = .white
        contentView.addSubview(emojiLabel)
        emojiLabel.snp.makeConstraints {
            $0.width.height.equalTo(24)
            
            $0.leading.equalToSuperview().offset(NotesViewConstants.cellHorizontalSpace)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(emojiLabel.snp.trailing).offset(NotesViewConstants.cellHorizontalSpace)
            $0.trailing.equalToSuperview().offset(-ContextMenuCell.padding)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(checkImageView)
        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-ContextMenuCell.padding)
            $0.centerY.equalToSuperview()
        }
        
    }
}
