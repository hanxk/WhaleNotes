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
    
    func setLocalImage(fileURL: URL,cornerRadius:CGFloat = 0,imageW:CGFloat = 0,completionHandler:(()->Void)? = nil) {
        let localPathProvider: LocalFileImageDataProvider = {
            let provider = LocalFileImageDataProvider(fileURL: fileURL)
            return provider
        }()
        var options:KingfisherOptionsInfo =  [
//            .transition(.fade(0.25))
//            .scaleFactor(UIScreen.main.scale),
        ]
//        if cornerRadius > 0 {
//            let processor = RoundCornerImageProcessor(cornerRadius: cornerRadius)
//            options.append(.processor(processor))
//        }
        let processor = DownsamplingImageProcessor(size: CGSize(width: imageW, height: imageW)) |> RoundCornerImageProcessor(cornerRadius: cornerRadius)
        if imageW > 0 {
            options.append(.processor(processor))
            options.append(.scaleFactor(UIScreen.main.scale))
        }
        self.kf.setImage(with: localPathProvider, placeholder: nil, options: options, progressBlock: nil) { result in
            completionHandler?()
        }
    }
    
}
