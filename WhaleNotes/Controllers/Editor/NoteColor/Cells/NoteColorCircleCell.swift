//
//  NoteColorCircleCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/26.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class NoteColorCircleCell: UICollectionViewCell {
    
    var colorInfo:(String,String)! {
        didSet {
            self.colorView.backgroundColor = UIColor(hexString: colorInfo.0)
            self.label.text = colorInfo.1
        }
    }
    
    var isChecked:Bool = false {
        didSet {
            self.checkImageView.isHidden = !isChecked
        }
    }
    var callbackColorSelected:((NoteBackground)->Void)!
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
     let colorView  = UIButton().then {
        $0.layer.borderWidth  = 1
        $0.layer.borderColor  =  UIColor.colorBoarder.cgColor
    }
    
    
    private let label: UILabel = UILabel().then {
        $0.font = UIFont.systemFont(ofSize: 16)
        $0.textColor = .primaryText
    }
    
    private let checkImageView: UIImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark", pointSize: 20, weight: .regular)
        $0.tintColor = UIColor.cardText
        $0.isHidden = true
    }
    
    
    
    private func setupUI() {
        addSubview(colorView)
        colorView.snp.makeConstraints {
            $0.width.height.equalToSuperview()
        }
        colorView.layer.cornerRadius = self.frame.width/2
        
        addSubview(checkImageView)
        checkImageView.snp.makeConstraints {
            $0.center.equalTo(colorView)
        }
        
    }
}
