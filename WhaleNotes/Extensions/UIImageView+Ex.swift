//
//  UIImage+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImageView {
    
    func setLocalImage(fileURL: URL,cornerRadius:CGFloat = 0,completionHandler:(()->Void)? = nil) {
        let localPathProvider: LocalFileImageDataProvider = {
            let provider = LocalFileImageDataProvider(fileURL: fileURL)
            return provider
        }()
        
        var options:KingfisherOptionsInfo = []
        if cornerRadius > 0 {
            let processor = RoundCornerImageProcessor(cornerRadius: cornerRadius)
            options.append(.processor(processor))
        }
        self.kf.setImage(with: localPathProvider, options: options)
        self.kf.setImage(with: localPathProvider, placeholder: nil, options: options, progressBlock: nil) { _ in
            completionHandler?()
        }
    }
    
}
