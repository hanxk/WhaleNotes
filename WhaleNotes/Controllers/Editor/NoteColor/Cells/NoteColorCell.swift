//
//  NoteColorCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

class NoteColorCell: UICollectionViewCell {
    
    static let cellHeight:CGFloat = 48
    
    var color:String = "" {
        didSet {
            if color == "#FFFFFF" {
                self.colorView.layer.borderWidth  = 1
                self.colorView.layer.borderColor  =  UIColor(hexString: "#C9C9C9").cgColor
            }else {
                
                self.colorView.layer.borderWidth  = 0
            }
            self.colorView.backgroundColor = UIColor(hexString: color)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let colorView  = UIView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = NoteColorCell.cellHeight / 2
        $0.backgroundColor = .placeHolderColor
    }
    
    private func setupUI() {
        contentView.addSubview(colorView)
        colorView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(NoteColorCell.cellHeight)
        }
    }
    
    @objc func handleButtonTapped() {
        
    }
}
