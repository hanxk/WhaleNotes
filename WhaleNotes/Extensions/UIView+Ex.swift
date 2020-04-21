//
//  UIView+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/21.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit

extension UIView {
    
    var safeArea: ConstraintBasicAttributesDSL {
        #if swift(>=3.2)
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.snp
            }
            return self.snp
        #else
            return self.snp
        #endif
    }
}
