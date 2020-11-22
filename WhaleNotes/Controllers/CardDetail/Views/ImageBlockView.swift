//
//  ImageBlockView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class ImageBlockView: BaseCardEditorView {
    
    private var imageBlock:BlockInfo!
    private var imageProperties:BlockImageProperty {
        return imageBlock.blockImageProperties!
    }
    private var imageZoomView:ImageZoomView!
    
    init(imageBlock:BlockInfo) {
        super.init(frame: .zero)
        self.imageBlock = imageBlock
        
        let imageUrlPath = ImageUtil.sharedInstance.dirPath.appendingPathComponent(imageProperties.url).absoluteString
        self.imageZoomView = ImageZoomView(frame: .zero, image: UIImage(contentsOfFile: imageUrlPath)!, imageSize: CGSize(width: CGFloat(imageProperties.width), height: CGFloat(imageProperties.height)))
        self.initializeUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initializeUI() {
        addSubview(imageZoomView)
        imageZoomView.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
    }
}
