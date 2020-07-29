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
import FloatingPanel

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
        self.extendedLayoutIncludesOpaqueBars = true
        
        func openBoardSetting(board: BlockInfo) {
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
            let vc = MyNavigationController(rootViewController: settingVC)
            self.present(vc, animated: true, completion: nil)
        }
        
        titleButton.callbackTapped = {
            switch self.sideMenuItemType {
                case .board(let board):
                    openBoardSetting(board: board)
                    break
                case .system(let menuInfo):
                    if case .board(let board) = menuInfo {
                        openBoardSetting(board: board)
                    }
                    break
               case .none:
                   break
            }
            
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = .bg
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}


//MARK: board edited
extension HomeViewController {
    private func handleBoardUpdated(board:BlockInfo) {
        self.sideMenuItemType = SideMenuItem.board(board: board)
        let properties = board.blockBoardProperties!
        titleButton.setTitle(properties.title,emoji: properties.icon)

        self.sideMenuViewController.boardIsUpdated(board:board)
        
    }
    
    private func handleBoardDeleted(board:BlockInfo) {
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
                if case .trash = systemMenu {
                   titleButton.isEnabled = false
                }else {
                   titleButton.isEnabled = true
                }
                self.setupSystemMenu(systemMenu: systemMenu)
                break
        }
    }
    
    func setupBoardView(board:BlockInfo) {
        if let oldView =  self.contentView {
            oldView.removeFromSuperview()
        }
        let window = UIApplication.shared.windows.first { $0.isKeyWindow }
        let height = self.view.frame.height - (window?.safeAreaInsets.bottom ?? 0)
        let notesView = NotesView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: height),board: board)
        notesView.callbackSearchButtonTapped = { _ in
            self.handleShowSearchbar()
        }
        self.contentView = notesView
        self.view.backgroundColor = .toolbarBg

        self.view.addSubview(notesView)
        notesView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let blockBoardProperties = board.blockBoardProperties,
           blockBoardProperties.type == BoardType.user
           {
            
           titleButton.setTitle(blockBoardProperties.title,emoji: blockBoardProperties.icon)
        }
        
    }
    
    func setupSystemMenu(systemMenu: MenuSystemItem) {
        switch systemMenu {
        case .board(let board):
             self.setupBoardView(board:board)
            if let blockBoardProperties = board.blockBoardProperties {
                self.titleButton.setTitle(blockBoardProperties.title, icon:systemMenu.iconImage)
            }
            break
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
        self.view.backgroundColor = .
            
            
            
            
            
            
            bg
        self.view.addSubview(trashView)
        trashView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}


extension HomeViewController {
    
    private func setupNavgationBar() {
        let button =  UIButton()
        button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        button.contentHorizontalAlignment = .leading
        button.setImage(UIImage(named: "ico_menu")?.withTintColor(UIColor.iconColor), for: .normal)
        button.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: button)
        
        self.navigationItem.leftBarButtonItems = [barButton]
        self.navigationItem.titleView = titleButton
        
        if let titleView = self.navigationItem.titleView  {
            titleView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.height.equalToSuperview()
            }
        }
        
        let config = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let search =  UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle",withConfiguration: config), style: .plain, target: self, action: #selector(handleShowSearchbar))
//        let more =  UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItems = [search]
    }
    
    @objc func toggleSideMenu () {
        if let vc = SideMenuManager.default.leftMenuNavigationController {
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func handleShowSearchbar() {
        let vc = SearchViewController()
        vc.callbackOpenBoard = { [weak self] boardBlock in
            self?.sideMenuViewController.setBoardSelected(boardBlock: boardBlock)
        }
        vc.callbackNoteEdited = { [weak self] editorMode in
            self?.handleEditorMode(editorMode)
        }
        let navVC = MyNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .overFullScreen
        navVC.modalTransitionStyle = .crossDissolve
        self.navigationController?.present(navVC, animated: true, completion: nil)
    }
    
    private func handleEditorMode(_ editorMode:EditorUpdateMode) {
//        if let notesView =  self.contentView as? NotesView {
//            notesView.noteEditorUpdated(mode: editorMode)
//            return
//        }
//        if let trashView =  self.contentView as? TrashView {
//            trashView.noteEditorUpdated(mode: editorMode)
//            return
//        }
    }
    
    private func selectedPresentationStyle() -> SideMenuPresentationStyle {
        let modes: [SideMenuPresentationStyle] = [.menuSlideIn, .viewSlideOut, .viewSlideOutMenuIn, .menuDissolveIn]
        return modes[2]
    }
    
    func makeSettings() -> SideMenuSettings {
        let presentationStyle = selectedPresentationStyle()
        presentationStyle.backgroundColor = .bg
        //        presentationStyle.menuStartAlpha = CGFloat(menuAlphaSlider.value)
        //        presentationStyle.menuScaleFactor = CGFloat(menuScaleFactorSlider.value)
        //        presentationStyle.onTopShadowOpacity = shadowOpacitySlider.value
        presentationStyle.presentingEndAlpha = 0.2
        //        presentationStyle.presentingScaleFactor = CGFloat(presentingScaleFactorSlider.value)
        var settings = SideMenuSettings()
        settings.presentationStyle = presentationStyle
        settings.menuWidth = view.frame.width - 52
        settings.statusBarEndAlpha = 0
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
        SideMenuManager.default.leftMenuNavigationController?.dismiss(animated: true, completion: nil)
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
