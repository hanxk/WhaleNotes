//
//  UIViewController+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/30.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import MBProgressHUD


extension UITableViewController {
    func showHudForTable(_ message: String) {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = message
        hud.isUserInteractionEnabled = false
        hud.layer.zPosition = 2
        self.tableView.layer.zPosition = 1
    }
}

extension UIViewController {
    func showHud(_ message: String = "") {
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)
        hud.label.text = message
        hud.isUserInteractionEnabled = false
    }

    func hideHUD() {
        MBProgressHUD.hide(for: self.view, animated: true)
    }
}
