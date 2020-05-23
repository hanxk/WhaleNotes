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
    
    var controller:UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.controller
        } else {
            return nil
        }
    }
    
}
