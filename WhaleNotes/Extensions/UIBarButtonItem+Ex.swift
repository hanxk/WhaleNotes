//
//  UIBarButtonItem+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/24.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit


extension UIBarButtonItem {

    var view:UIView?{
        return (value(forKey: "view") as? UIView)
    }


    static func menuButtonWithHeight(_ target: Any?, action: Selector,imageName: String,width:CGFloat=24,height:CGFloat = 24) -> UIBarButtonItem {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName:imageName), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        button.backgroundColor = .blue

        let menuBarItem = UIBarButtonItem(customView: button)
        menuBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        menuBarItem.customView?.heightAnchor.constraint(equalToConstant: height).isActive = true
        menuBarItem.customView?.widthAnchor.constraint(equalToConstant: width).isActive = true

        return menuBarItem
    }
    
    static func customViewWithHeight(_ customView:UIView,width:CGFloat = 24,height:CGFloat = 24) -> UIBarButtonItem {
        let menuBarItem = UIBarButtonItem(customView: customView)
        menuBarItem.customView?.translatesAutoresizingMaskIntoConstraints = false
        menuBarItem.customView?.heightAnchor.constraint(equalToConstant: height).isActive = true
        menuBarItem.customView?.widthAnchor.constraint(equalToConstant: width).isActive = true

        return menuBarItem
    }
}


extension UINavigationBar {
    func transparentNavigationBar() {
        self.setBackgroundImage(UIImage(), for: .default) //UIImage.init(named: "transparent.png")
        self.shadowImage = UIImage()
    //        self.isTranslucent = true
        self.backgroundColor = UIColor.statusbar.withAlphaComponent(0.92)
    }
}
