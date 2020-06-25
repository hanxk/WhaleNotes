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
    

        open class var cardText: UIColor {
            get {
    //            return UIColor(named: "PrimaryText")!
//                 UIColor.init(hexString: "#333333")
                 UIColor.init(hexString: "#2b292e")
            }
        }
    
    open class var primaryText: UIColor {
        get {
//            return UIColor(named: "PrimaryText")!
             UIColor.init(hexString: "#2b292e")
        }
    }
    open class var primaryText2: UIColor {
         get {
             return UIColor(hexString: "#333333")
         }
     }
    
    open class var buttonTintColor: UIColor {
        get {
            return UIColor(named: "ButtonTintColor")!
        }
    }
    
    open class var colorBoarder: UIColor {
           get {
//               return UIColor(red: 0.098, green: 0.086, blue: 0.114, alpha: 0.08)
            return UIColor(red: 0, green: 0, blue: 0, alpha: 0.04)
           }
    }
    
    open class var thirdColor: UIColor {
        get {
            return UIColor(named: "ThirdColor")!
        }
    }
    
    
    open class var bg: UIColor {
        get {
            return UIColor.init(hexString: "#EFEFEF")
        }
    }
    
    
    open class var tappedColor: UIColor {
        get {
            return UIColor(hexString: "#F8F8F8")
        }
    }
    
    
    open class var iconColor: UIColor {
        get {
            return UIColor(hexString: "#444444")
        }
    }
    
    
    open class var divider: UIColor {
        get {
            return UIColor(hexString: "#ECECEC")
        }
    }
    
    open class var placeHolderColor: UIColor {
        get {
            return UIColor(named: "PlaceHolder")!
        }
    }
    
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
    
    open class var sidemenuBg: UIColor {
        get {
            return UIColor.init(hexString: "#F6F6F6")
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
}
