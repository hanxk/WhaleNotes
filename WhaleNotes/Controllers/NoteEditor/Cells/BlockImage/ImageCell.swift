//
//  ImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

class ImageCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView  = UIView().then {
        $0.backgroundColor = .red
    }
    
    lazy var itemSize = (UIScreen.main.bounds.size.width - NoteEditorViewController.space*2 - NoteEditorViewController.cellSpace)/2
    
    private func setupUI() {
        
        
        //        contentView.backgroundColor = .red
        //        contentView.snp.makeConstraints { (make) in
        //            make.width.height.equalTo(itemSize)
        //        }
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(itemSize)
            
            
            make.top.equalToSuperview().priority(750)
            make.bottom.equalToSuperview().offset(-4)
            
            make.leading.equalToSuperview().priority(750)
            make.trailing.equalToSuperview()
        }
    }
    
}
