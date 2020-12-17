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
            return UIColor(hexString: "#0087FE")!
        }
    }
    
    
    open class var primaryText: UIColor {
        get {
            //  2b292e          return UIColor(named: "PrimaryText")!
            UIColor.init(hexString: "#333333")
        }
    }
    open class var primaryText2: UIColor {
        get {
            return UIColor(hexString: "#333333")
        }
    }
    
    open class var buttonTintColor: UIColor {
        get {
            return UIColor(red: 0.188, green: 0.192, blue: 0.2, alpha: 0.9)
        }
    }
    
    open class var colorBoarder: UIColor {
        get {
            //            UIColor(red: 0.098, green: 0.086, blue: 0.114, alpha: 0.08).cgColor
//            return UIColor(red: 0.098, green: 0.086, blue: 0.114, alpha: 0.06)
//                        return UIColor(hexString: "#EFF0F1")
            return  UIColor(red: 0, green: 0, blue: 0, alpha: 0.9)


        }
    }
    
    open class var thirdColor: UIColor {
        get {
            return UIColor(named: "ThirdColor")!
        }
    }
    
    
    
    
    open class var tappedColor: UIColor {
        get {
            return UIColor(hexString: "#F8F8F8")
        }
    }
    
    
    open class var iconColor: UIColor {
        get {
//            return UIColor(red: 0.122, green: 0.133, blue: 0.145, alpha: 1)
            return  UIColor(hexString: "#1F2225")
        }
    }
    
    
    open class var divider: UIColor {
        get {
            return UIColor(hexString: "#ECECEC")
        }
    }
    
    
    open class var dividerGray: UIColor {
        get {
            return UIColor(hexString: "#DDDDDD")
        }
    }
    
    open class var placeHolderColor: UIColor { return UIColor(named: "PlaceHolder")! }
    open class var settingbg: UIColor { return UIColor(hexString: "#F4F4F4") }
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}


// sidebar
extension UIColor {
    
    // OLD: #EFEFEF E8EAED
    
    open class var sidemenuBg: UIColor {
        get {
            return UIColor.init(hexString: "#FFFFFF")
        }
    }
    open class var sidemenuSelectedBg: UIColor {
        get {
            return UIColor.init(hexString: "#E8E8E8")
        }
    }
    
    open class var sidemenuText: UIColor {
        get {
            return UIColor.init(hexString: "#202020")
        }
    }
    
    
    open class var chkCheckedTextColor: UIColor {
        get {
            UIColor(red: 0.216, green: 0.208, blue: 0.184, alpha: 0.38)
        }
    }
    
}

//MARK: Toolbar
extension UIColor {
    
    open class var toolbarBg: UIColor {
        get {
           return  UIColor(hexString: "#FAFAFB")
        }
    }
    
    open class var toolbarIcon: UIColor {
        get {
            return  UIColor.black.withAlphaComponent(0.8)
        }
    }
}

extension UIColor {
    
    open class var popMenuBg: UIColor {
        get {
//            return UIColor.init(hexString: "#E3E3E5")
            return UIColor.init(hexString: "#FFFFFF")
        }
    }
    open class var popMenuHighlight: UIColor {
        get {
            return UIColor.init(hexString: "#D3D3D6")
        }
    }
    
    
    open class var popMenuIconTint: UIColor {
        get {
            return UIColor.init(hexString: "#000000")
        }
    }
    open class var popMenuText: UIColor {
        get {
            return UIColor.init(hexString: "#000000")
        }
    }
}


extension UIColor {
    
    open class var bg: UIColor {
        get {
            
            return UIColor.init(hexString: "#F8F8F8")
        }
    }
    
    open class var cardText: UIColor {
        get {
            UIColor.init(hexString: "#333333")
        }
    }
    
    
    open class var cardTextSecondary: UIColor {
        get {
            UIColor.init(hexString: "#6F6F6F")
        }
    }
    
    
    open class var cardBorder: UIColor {
        get {
            return UIColor(hexString: "#E8E8E8")
        }
    }
}
