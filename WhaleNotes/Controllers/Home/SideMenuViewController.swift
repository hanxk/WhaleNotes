//
//  SideMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

class SideMenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bg = UIColor(red: 0.961, green: 0.965, blue: 0.973, alpha: 1)
        _ = self.navigationController?.navigationBar.then {
            $0.barTintColor = bg
            $0.isTranslucent = false
            $0.shadowImage = UIImage()
            
            let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.init(hexString: "#BDBEBF"),
                                  NSAttributedString.Key.font:UIFont.systemFont(ofSize: 15)
            ]
            $0.titleTextAttributes = textAttributes
        }
        self.title = "小鲸鱼"
        self.view.backgroundColor = bg
    }

}
