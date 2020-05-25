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

}

