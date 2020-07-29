//
//  ForgotPasswordPresentationController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit

struct BottomPresentationConfig {
    var height:CGFloat = 150
    var alpha:CGFloat = 0.1
    var cornerRadius:CGFloat = 15
}
class BottomPresentationController: UIPresentationController{
    
    private lazy var dimView: UIView = UIView().then {
        $0.backgroundColor = .black
        $0.isUserInteractionEnabled = true
        
        var tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        $0.addGestureRecognizer(tapGestureRecognizer)
    }
    private lazy var config:BottomPresentationConfig = BottomPresentationConfig()
    
    @objc func dismiss(){
        self.presentedViewController.dismiss(animated: true, completion: nil)
    }
    convenience init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?,config:BottomPresentationConfig) {
        self.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.config = config
        self.dimView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        
    }
//    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
//        let blurEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
//        blurEffectView = UIVisualEffectView(effect: blurEffect)
//        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
//        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
//        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        self.blurEffectView.isUserInteractionEnabled = true
//        self.blurEffectView.addGestureRecognizer(tapGestureRecognizer)
//    }
    override var frameOfPresentedViewInContainerView: CGRect{
//        return CGRect(origin: CGPoint(x: 0, y: self.containerView!.frame.height/2), size: CGSize(width: self.containerView!.frame.width, height: self.containerView!.frame.height/2))
        let y = self.containerView!.frame.height - config.height
        return CGRect(origin: CGPoint(x: 0, y: y), size: CGSize(width: self.containerView!.frame.width, height: config.height))
    }
    override func dismissalTransitionWillBegin() {
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.dimView.alpha = 0
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            self.dimView.removeFromSuperview()
        })
    }
    override func presentationTransitionWillBegin() {
        self.dimView.alpha = 0
        self.containerView?.addSubview(dimView)
        self.presentedViewController.transitionCoordinator?.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) in
            self.dimView.alpha = self.config.alpha
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in

        })
    }
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView!.layer.masksToBounds = true
        presentedView!.layer.smoothCornerRadius =  config.cornerRadius
    }
    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        self.presentedView?.frame = frameOfPresentedViewInContainerView
        dimView.frame = containerView!.bounds
    }
}



