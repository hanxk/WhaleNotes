//
//  UIColor+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/19.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

extension UIColor {
    open class var brand: UIColor {
        get {
            return  UIColor(named: "Brand")!
        }
    }
    open class var primaryText: UIColor {
        get {
            return UIColor(named: "PrimaryText")!
        }
    }
    
    open class var buttonTintColor: UIColor {
        get {
            return UIColor(named: "ButtonTintColor")!
        }
    }
}
