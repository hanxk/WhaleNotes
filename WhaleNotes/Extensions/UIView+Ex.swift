//
//  UIView+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/21.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SnapKit
import Toast_Swift

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
    
//    func addBorder(edge: UIRectEdge, color: UIColor, thickness: CGFloat) {
//        let border = CALayer()
//        switch edge {
//        case UIRectEdge.top:
//            border.frame = CGRect(x: 0, y: 0, width: frame.width, height: thickness)
//        case UIRectEdge.bottom:
//            border.frame = CGRect(x:0, y: frame.height - thickness, width: frame.width, height:thickness)
//        case UIRectEdge.left:
//            border.frame = CGRect(x:0, y:0, width: thickness, height: frame.height)
//        case UIRectEdge.right:
//            border.frame = CGRect(x: frame.width - thickness, y: 0, width: thickness, height: frame.height)
//        default: do {}
//        }
//        border.backgroundColor = color.cgColor
//        self.layer.addSublayer(border)
//    }
    
    public func removeSubviews() {
         for subview in subviews {
             subview.removeFromSuperview()
         }
     }
}

extension CALayer {
    
    var smoothCornerRadius:CGFloat {
        set {
            self.cornerCurve = .continuous
            self.cornerRadius = newValue
        }
        get {
            return self.cornerRadius
        }
    }
}

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
