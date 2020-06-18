//
//  UIViewController+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/30.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import MBProgressHUD
import ContextMenu


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

extension UIViewController {
    func showAlertMessage(message:String,positiveButtonText:String,isPositiveDestructive:Bool = false,callbackPositive:@escaping ()->Void) {
        let alertVC = MessageAlertViewController()
        alertVC.positiveButtonText = positiveButtonText
        alertVC.callbackPositive = callbackPositive
        alertVC.isPositiveDestructive = isPositiveDestructive
        alertVC.msg = message
        showAlertViewController(alertVC)
    }
    
    func showAlertTextField(title:String = "",text:String = "",placeholder:String = "",callbackPositive:@escaping (String)->Void) {
        let alertVC = TextFieldAlertViewController()
        alertVC.callbackPositive = callbackPositive
        alertVC.alertTitle = title
        alertVC.text = text
        alertVC.placeholder = placeholder
        showAlertViewController(alertVC)
    }
    
    
    func showAlertViewController(_ alertVC: BaseAlertViewController) {
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func showContextMenu(sourceView:UIView) {
        guard let sourceVC = sourceView.controller else { return }
        ContextMenu.shared.show(
                sourceViewController: sourceVC,
                viewController: self,
                options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(shadowOpacity:0.06,overlayColor: UIColor.black.withAlphaComponent(0.3))),
                sourceView: sourceView
            )
    }
}
