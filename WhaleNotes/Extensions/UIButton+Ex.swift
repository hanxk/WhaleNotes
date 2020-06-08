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
}
