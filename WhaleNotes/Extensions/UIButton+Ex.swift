//
//  UIButton+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/6.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

extension UIButton {
//    func setInsets(
//        forContentPadding contentPadding: UIEdgeInsets,
//        imageTitlePadding: CGFloat
//    ) {
//        self.contentEdgeInsets = UIEdgeInsets(
//            top: contentPadding.top,
//            left: contentPadding.left,
//            bottom: contentPadding.bottom,
//            right: contentPadding.right + imageTitlePadding
//        )
//        self.titleEdgeInsets = UIEdgeInsets(
//            top: 0,
//            left: imageTitlePadding,
//            bottom: 0,
//            right: -imageTitlePadding
//        )
//    }
    
    func setImageTitleSpace(_ space: CGFloat) {
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: space,
            bottom: 0,
            right: -space
        )
    }
    
    func leftImage(image: UIImage, renderMode: UIImage.RenderingMode) {
         self.setImage(image.withRenderingMode(renderMode), for: .normal)
         self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: image.size.width / 2)
         self.contentHorizontalAlignment = .left
         self.imageView?.contentMode = .scaleAspectFit
     }

    func rightImage(image: UIImage, renderMode: UIImage.RenderingMode){
         self.setImage(image.withRenderingMode(renderMode), for: .normal)
         self.imageEdgeInsets = UIEdgeInsets(top: 0, left:image.size.width / 2, bottom: 0, right: 0)
         self.contentHorizontalAlignment = .right
         self.imageView?.contentMode = .scaleAspectFit
     }
}
