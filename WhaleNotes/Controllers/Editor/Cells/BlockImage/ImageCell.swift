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
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.divider.cgColor
    }
    
    var imageBlock:Block! {
        didSet {
            let fileURL = ImageUtil.sharedInstance.filePath(imageName: imageBlock.blockImageProperties!.url)
            imageView.setLocalImage(fileURL: fileURL)
        }
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        contentView.backgroundColor = .clear
    }
    
}
