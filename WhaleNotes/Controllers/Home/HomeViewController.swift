//
//  HomeViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/17.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import SideMenu
import SnapKit
import Then
import ContextMenu
import PopMenu
import TLPhotoPicker
import RxSwift
import Photos

class HomeViewController: UIViewController, UINavigationControllerDelegate {
    
    
    private lazy var disposeBag = DisposeBag()
    
    private var notesView:NotesView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    private func setup() {
        self.setupNavgationBar()
        self.setupSideMenu()
        
        let notesView = NotesView(frame: self.view.frame)
        self.notesView = notesView
        self.view.addSubview(notesView)
            notesView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        notesView?.viewWillAppear(animated)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notesView?.viewWillDisappear(animated)
    }
}


extension HomeViewController {
    
    private func setupNavgationBar() {
        let button =  UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 44)
        button.setImage(UIImage(named: "ico_menu"), for: .normal)
        button.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        
        let label = UILabel()
        label.text = "东京旅行"
        label.textAlignment = .left
        label.backgroundColor = UIColor.clear
        let labelItem = UIBarButtonItem(customView: label)
        
        self.navigationItem.leftBarButtonItems = [barButton,labelItem]
        
        let search =  UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: nil)
        let more =  UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItems = [more,search]
    }
    
    @objc func toggleSideMenu (sender:UIButton) {
        print("action")
        if let vc = SideMenuManager.default.leftMenuNavigationController {
            present(vc, animated: true, completion: nil)
        }
    }
    
    
    private func selectedPresentationStyle() -> SideMenuPresentationStyle {
        let modes: [SideMenuPresentationStyle] = [.menuSlideIn, .viewSlideOut, .viewSlideOutMenuIn, .menuDissolveIn]
        return modes[2]
    }
    
    func makeSettings() -> SideMenuSettings {
        let presentationStyle = selectedPresentationStyle()
        //        presentationStyle.backgroundColor = .white
        //        presentationStyle.menuStartAlpha = CGFloat(menuAlphaSlider.value)
        //        presentationStyle.menuScaleFactor = CGFloat(menuScaleFactorSlider.value)
        //        presentationStyle.onTopShadowOpacity = shadowOpacitySlider.value
        //        presentationStyle.presentingEndAlpha = CGFloat(presentingAlphaSlider.value)
        //        presentationStyle.presentingScaleFactor = CGFloat(presentingScaleFactorSlider.value)
        var settings = SideMenuSettings()
        settings.presentationStyle = presentationStyle
        settings.menuWidth = view.frame.width - 41*UIScreen.main.scale
        settings.statusBarEndAlpha = 0
        //        let styles:[UIBlurEffect.Style?] = [nil, .dark, .light, .extraLight]
        //        settings.blurEffectStyle = styles[blurSegmentControl.selectedSegmentIndex]
        //        settings.statusBarEndAlpha = blackOutStatusBar.isOn ? 1 : 0
        
        return settings
    }
    
    func setupSideMenu() {
        let settings = makeSettings()
        SideMenuManager.default.leftMenuNavigationController?.settings = settings
        
        if let navigationController = navigationController {
            SideMenuManager.default.addPanGestureToPresent(toView: navigationController.navigationBar)
            SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.view,forMenu: .left)
        }
    }
    
    
}
