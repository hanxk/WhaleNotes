//
//  NoteColorCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class NoteColorCell: UICollectionViewCell {
    
    static let cellHeight:CGFloat = 44
    static private let colorWidth:CGFloat = 28
    
    var colorInfo:(NoteBackground,String)! {
        didSet {
            self.colorView.backgroundColor = colorInfo.0.uicolor
            self.label.text = colorInfo.1
        }
    }
    
    var isChecked:Bool = false {
        didSet {
            self.checkImageView.isHidden = !isChecked
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let colorView  = UIView().then {
        $0.layer.smoothCornerRadius = 4
        $0.layer.borderWidth  = 1
        $0.layer.borderColor  =  UIColor.colorBoarder.cgColor
    }
    
    
    private let label: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .primaryText
    }
    
    private let checkImageView: UIImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark", pointSize: 15, weight: .regular)
        $0.tintColor = UIColor.init(hexString: "#666666")
        $0.isHidden = true
    }
    
    
    
    private func setupUI() {
        contentView.addSubview(colorView)
        colorView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(ContextMenuCell.padding)
            $0.width.height.equalTo(NoteColorCell.colorWidth)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalTo(colorView.snp.trailing).offset(ContextMenuCell.spacing)
            $0.centerY.equalToSuperview()
        }
        
        contentView.addSubview(checkImageView)
        checkImageView.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-ContextMenuCell.padding)
            $0.centerY.equalToSuperview()
        }
        
    }
    
    @objc func handleButtonTapped() {
        
    }
}
