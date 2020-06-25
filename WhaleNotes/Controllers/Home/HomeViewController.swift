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
    
    private var contentView:UIView?
    private var sideMenuItemType:SideMenuItem! {
        didSet {
            if oldValue == sideMenuItemType {
                return
            }
            self.setupContentView()
        }
    }
    
    private let titleButton:HomeTitleView = HomeTitleView()
    
    
    private lazy var sideMenuViewController = SideMenuViewController().then {
        $0.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    private func setup() {
        self.setupNavgationBar()
        self.setupSideMenu()
        self.view.backgroundColor = .bg
        
        titleButton.callbackTapped = {
            if case .board(let board) = self.sideMenuItemType {
                let settingVC = BoardSettingViewController()
                settingVC.board = board
                settingVC.callbackBoardSettingEdited = { boardEditedType in
                    switch boardEditedType {
                    case .update(let board):
                        self.handleBoardUpdated(board: board)
                    case .delete(let board):
                        self.handleBoardDeleted(board: board)
                    }
                }
                self.present(MyNavigationController(rootViewController: settingVC), animated: true, completion: nil)
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        notesView?.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = .bg
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        notesView?.viewWillDisappear(animated)
//self.navigationController?.navigationBar.barTintColor = .white
    }
    
}


//MARK: board edited
extension HomeViewController {
    private func handleBoardUpdated(board:Board) {
        self.sideMenuItemType = SideMenuItem.board(board: board)
        titleButton.setTitle(board.title,emoji: board.icon)
        
        self.sideMenuViewController.boardIsUpdated(board:board)
        
    }
    
    private func handleBoardDeleted(board:Board) {
//        titleButton.setTitle(board.title,emoji: board.icon)
        self.sideMenuViewController.boardIsDeleted(board: board)
    }
}

//MARK: content view
extension HomeViewController {
    
    func setupContentView() {
        
        guard let sideMenuItemType = self.sideMenuItemType else { return }
        
        switch sideMenuItemType {
            case .board(let board):
                titleButton.isEnabled = true
                self.setupBoardView(board:board)
                break
            case .system(let systemMenu):
                titleButton.isEnabled = false
                self.setupSystemMenu(systemMenu: systemMenu)
                break
        }
    }
    
    func setupBoardView(board:Board) {
        if let oldView =  self.contentView {
            oldView.removeFromSuperview()
        }
        let notesView = NotesView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.contentView = notesView
        self.view.addSubview(notesView)
        notesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        notesView.board = board
        if board.type == BoardType.user.rawValue {
            titleButton.setTitle(board.title,emoji: board.icon)
        }
        
    }
    
    func setupSystemMenu(systemMenu: MenuSystemItem) {
        switch systemMenu {
        case .board(let board):
             self.setupBoardView(board:board)
             self.titleButton.setTitle(board.title, icon:systemMenu.iconImage)
        case .trash:
            self.titleButton.setTitle(systemMenu.title, icon:systemMenu.iconImage)
            self.setupTrashView()
        }
    }
    
    func setupTrashView() {
        
        if let oldView =  self.contentView {
            oldView.removeFromSuperview()
        }
        let trashView = TrashView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        self.contentView = trashView
        self.view.addSubview(trashView)
        trashView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}


extension HomeViewController {
    
    private func setupNavgationBar() {
        let button =  UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 44)
        button.setImage(UIImage(named: "ico_menu")?.withTintColor(UIColor.iconColor), for: .normal)
        button.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        
        //        let label = UILabel()
        //        label.text = "东京旅行"
        //        label.textAlignment = .left
        //        label.backgroundColor = UIColor.clear
        //        let labelItem = UIBarButtonItem(customView: label)
//        self.navigationItem.title = "东京旅行"
//        self.navigationItem.largeTitleDisplayMode = .automatic
        self.navigationItem.leftBarButtonItems = [barButton]
        self.navigationItem.titleView = titleButton
        
        if let titleView = self.navigationItem.titleView  {
//            titleView.translatesAutoresizingMaskIntoConstraints = false
            titleView.snp.makeConstraints {
                let padding = 50
                $0.centerX.equalToSuperview()
//                $0.leading.equalToSuperview().offset(padding)
//                $0.trailing.equalToSuperview().offset(-padding)
                $0.height.equalToSuperview()
            }
        }
        
//        self.navigationController?.navigationBar.barTintColor  = .bg
        

        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        let search =  UIBarButtonItem(image: UIImage(systemName: "magnifyingglass",withConfiguration: config), style: .plain, target: self, action: nil)
        let more =  UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItems = [search]
    }
    
    @objc func toggleSideMenu () {
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
        presentationStyle.backgroundColor = .white
        //        presentationStyle.menuStartAlpha = CGFloat(menuAlphaSlider.value)
        //        presentationStyle.menuScaleFactor = CGFloat(menuScaleFactorSlider.value)
        //        presentationStyle.onTopShadowOpacity = shadowOpacitySlider.value
        presentationStyle.presentingEndAlpha = 0.1
        //        presentationStyle.presentingScaleFactor = CGFloat(presentingScaleFactorSlider.value)
        var settings = SideMenuSettings()
        settings.presentationStyle = presentationStyle
        settings.menuWidth = view.frame.width - 52
        settings.statusBarEndAlpha = 0.1
        //        let styles:[UIBlurEffect.Style?] = [nil, .dark, .light, .extraLight]
        //        settings.blurEffectStyle = styles[blurSegmentControl.selectedSegmentIndex
        
        return settings
    }
    
    func setupSideMenu() {
        let settings = makeSettings()
        
        // Define the menus
        
        let leftMenuNavigationController = SideMenuNavigationController(rootViewController: sideMenuViewController)
        leftMenuNavigationController.leftSide = true
        leftMenuNavigationController.sideMenuDelegate = self
        
        SideMenuManager.default.leftMenuNavigationController = leftMenuNavigationController
        SideMenuManager.default.leftMenuNavigationController?.settings = settings
        
        
        if let navigationController = navigationController {
            SideMenuManager.default.addPanGestureToPresent(toView: navigationController.navigationBar)
            SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: self.view,forMenu: .left)
        }
    }
}

extension HomeViewController:SideMenuViewControllerDelegate {
    
    func sideMenuItemSelected(menuItemType: SideMenuItem) {
        self.sideMenuItemType = menuItemType
//        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: nil)
    }
    //    func sideMenuSystemItemSelected(menuSystem: MenuSystemItem) {
    //        self.title = menuSystem.title
    //        self.dismissSideMenu()
    //    }
    //
    //    func sideMenuBoardItemSelected(board: Board) {
    //        self.title = board.title
    //        self.dismissSideMenu()
    //    }
    
    func dismissSideMenu() {
        
    }
}

extension HomeViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Appearing! (animated: \(animated))")
    }
    
    func sideMenuDidAppear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Appeared! (animated: \(animated))")
    }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappearing! (animated: \(animated))")
    }
    
    func sideMenuDidDisappear(menu: SideMenuNavigationController, animated: Bool) {
        print("SideMenu Disappeared! (animated: \(animated))")
    }
}
