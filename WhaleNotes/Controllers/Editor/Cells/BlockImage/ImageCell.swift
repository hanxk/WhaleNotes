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
    
    let imageView  = UIImageView().then {
        $0.clipsToBounds = true
        $0.layer.cornerRadius = AttachmentsConstants.radius
        $0.backgroundColor = .placeHolderColor
    }
    
    var imageBlock:Block2! {
        didSet {
            imageView.setLocalImage(filePath: ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageBlock.source).absoluteString)
        }
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
}
