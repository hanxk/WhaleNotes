//
//  ImageCell.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit
import Kingfisher

class ImageCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let imageView  = UIImageView()
    
    var image:Image! {
        didSet {
            imageView.kf.setImage(with: image.localPathProvider)
        }
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
}
