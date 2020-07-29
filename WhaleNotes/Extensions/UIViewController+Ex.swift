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
    
    var topbarHeight: CGFloat {
         return (view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0.0) +
             (self.navigationController?.navigationBar.frame.height ?? 0.0)
     }
}

extension UIViewController {
    func showAlertMessage(title:String? = nil,message:String,positiveButtonText:String,isPositiveDestructive:Bool = false,callbackPositive:@escaping ()->Void) {
//        let alertVC = MessageAlertViewController()
//        alertVC.positiveButtonText = positiveButtonText
//        alertVC.callbackPositive = callbackPositive
//        alertVC.isPositiveDestructive = isPositiveDestructive
//        alertVC.msg = message
//        showAlertViewController(alertVC)
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: positiveButtonText, style: isPositiveDestructive ? .destructive :.default, handler: { _ in
            callbackPositive()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func showAlertTextField(title:String = "",text:String = "",placeholder:String = "",positiveBtnText:String,callbackPositive:@escaping (String)->Void) {
//        let alertVC = TextFieldAlertViewController()
//        alertVC.callbackPositive = callbackPositive
//        alertVC.alertTitle = title
//        alertVC.text = text
//        alertVC.placeholder = placeholder
//        showAlertViewController(alertVC)
        let ac = UIAlertController(title:title, message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields![0].placeholder = placeholder
        ac.textFields![0].text = text
        
        let submitAction = UIAlertAction(title: positiveBtnText, style: .default) { [unowned ac] _ in
            let title = ac.textFields![0].text!.trimmingCharacters(in: .whitespaces)
            if title.isEmpty { return }
            callbackPositive(title)
        }
        ac.addAction(submitAction)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        ac.addAction(cancelAction)
        present(ac, animated: true)
        
    }
    
    
    func showAlertViewController(_ alertVC: BaseAlertViewController) {
        alertVC.modalPresentationStyle = .overFullScreen
        alertVC.modalTransitionStyle = .crossDissolve
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func showContextMenu(sourceView:UIView) {
        guard let sourceVC = sourceView.controller else { return }
        
        let containerStyle = ContextMenu.ContainerStyle(shadowOpacity:0.1,
                                                        xPadding: -sourceView.frame.width,
                                                        overlayColor: UIColor.black.withAlphaComponent(0.0))
        
        ContextMenu.shared.show(
                sourceViewController: sourceVC,
                viewController: self,
                options: ContextMenu.Options(containerStyle: containerStyle),
                sourceView: sourceView
            )
    }
    
    
    func generateUIBarButtonItem(imageName:String,imageSize:CGFloat = 19,action: Selector?) -> UIBarButtonItem {
        let weight:UIImage.SymbolWeight = .regular
        let image = UIImage(systemName: imageName, pointSize: imageSize, weight: weight)!
        return UIBarButtonItem(image: image, style: .plain, target: self, action: action)
    }
}
