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
    private lazy var navBar:UINavigationBar = UINavigationBar() .then{
        $0.isTranslucent = true
        $0.delegate = self
        let barAppearance =  UINavigationBarAppearance()
    //   barAppearance.configureWithDefaultBackground()
        barAppearance.configureWithDefaultBackground()
        $0.standardAppearance.backgroundColor = .bg
            
        $0.scrollEdgeAppearance = barAppearance
        $0.standardAppearance.shadowColor = nil
    }
    private var containerView:UIView = UIView()
    
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
        self.setupToolbar()
        self.extendedLayoutIncludesOpaqueBars = true
        self.view.backgroundColor = .bg
        
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


//MARK: tool bar
extension HomeViewController {
    
    private  func setupToolbar() {
        self.navigationController?.isToolbarHidden = false
        var items = [UIBarButtonItem]()
        items.append(generateUIBarButtonItem(systemName:"camera"))
        items.append(generateSpace())
        items.append(generateUIBarButtonItem(systemName:"photo.on.rectangle"))
        items.append(generateSpace())
        items.append(generateUIBarButtonItem(systemName:"mic"))
        items.append(generateSpace())
        items.append(generateUIBarButtonItem(systemName:"link"))
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        items.append(generateUIBarButtonItem(systemName:"plus.circle.fill",pointSize: 19))
        toolbarItems = items
        
        self.navigationController?.toolbar.frame = CGRect(x: 0, y: 0, width: 375, height: 54)
        self.navigationController?.toolbar.tintColor = .iconColor
        self.navigationController?.toolbar.barTintColor = UIColor(hexString: "#EBECEF")
        self.navigationController?.toolbar.isTranslucent = true
        DispatchQueue.main.async {
            self.navigationController?.toolbar.updateConstraintsIfNeeded()
        }
    }
    
    private func generateUIBarButtonItem(systemName:String,pointSize:CGFloat = 15) -> UIBarButtonItem {
        let item = UIBarButtonItem(image: UIImage(systemName: systemName, pointSize: pointSize), style: .plain, target: self, action: #selector(handleToolbarAction))
        return item
    }
    
    private func generateSpace() -> UIBarButtonItem {
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 12
        return space
    }
    
    
    @objc func handleToolbarAction () {
        
    }
    
}


//MARK: board edited
extension HomeViewController {
    private func handleBoardUpdated(board:BlockInfo) {
        self.sideMenuItemType = SideMenuItem.board(board: board)
        let properties = board.blockBoardProperties!
        titleButton.setTitle(board.title,emoji: properties.icon)
        
    }
    
    private func handleBoardDeleted(board:BlockInfo) {
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
        let topPadding = self.topbarHeight
        let height:CGFloat = self.view.frame.height - topPadding
        let boardView = BoardView(frame: CGRect(x: 0, y: topPadding, width: self.view.frame.width, height: height),board: board)
        self.contentView = boardView
        
        self.containerView.addSubview(boardView)
        boardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if let blockBoardProperties = board.blockBoardProperties,
           blockBoardProperties.type == .user
        {
            
            titleButton.setTitle(board.title,emoji: blockBoardProperties.icon)
        }
        
    }
    
    func setupSystemMenu(systemMenu: MenuSystemItem) {
        switch systemMenu {
        case .board(let board):
            self.setupBoardView(board:board)
            if let blockBoardProperties = board.blockBoardProperties {
                self.titleButton.setTitle(board.title, icon:systemMenu.iconImage)
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
        self.view.backgroundColor = .bg
        self.view.addSubview(trashView)
        trashView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

//MARK: nav bar
extension HomeViewController:UINavigationBarDelegate{
    
    private func setupUIFrame(){
        self.view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.height.width.equalToSuperview()
        }
        self.view.addSubview(navBar)
        navBar.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func setupNavgationBar() {
        self.setupUIFrame()
        
        let navItem = UINavigationItem()
        navBar.items = [navItem]
        
        let button =  UIButton().then {
            $0.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            $0.contentHorizontalAlignment = .leading
            $0.setImage(UIImage(named: "ico_menu")?.withTintColor(UIColor.iconColor), for: .normal)
            $0.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        }
        let barButton = UIBarButtonItem(customView: button)
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.text = "TCO_choose_reminder";
        
        
//        let titleView2 =  UIBarButtonItem(customView: titleButton)
        //        titleButton.backgroundColor = .red
        
        
        navItem.leftBarButtonItems = [barButton]
        navItem.titleView = titleButton
        
        if let titleView = self.navigationItem.titleView  {
            titleView.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.height.equalToSuperview()
            }
        }
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        //        let imageSize:CGFloat = 38
        //        let searchButton : UIButton = UIButton.init(type: .custom)
        ////        searchButton.backgroundColor = .red
        //        searchButton.setImage(UIImage(systemName: "magnifyingglass",withConfiguration: config), for: .normal)
        //        searchButton.addTarget(self, action: #selector(handleShowSearchbar), for: .touchUpInside)
        //        searchButton.frame = CGRect(x: 0, y: 0, width: imageSize, height: imageSize)
        //        let searchButtonItem = UIBarButtonItem(customView: searchButton)
        //
        //
        //        let menuButton : UIButton = UIButton.init(type: .custom)
        //        menuButton.setImage(UIImage(systemName: "ellipsis.circle",withConfiguration: config), for: .normal)
        //        menuButton.addTarget(self, action: #selector(handleShowSearchbar), for: .touchUpInside)
        //        menuButton.frame = CGRect(x: 0, y: 0, width: imageSize, height: imageSize)
        //        let menuButtonItem = UIBarButtonItem(customView: menuButton)
        
        let searchButtonItem =  UIBarButtonItem(image: UIImage(systemName: "magnifyingglass",withConfiguration: config), style: .plain, target: self, action: #selector(handleShowSearchbar))
        //        let more =  UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
        navItem.rightBarButtonItems = [searchButtonItem]
    }
    
    @objc func toggleSideMenu () {
        if let vc = SideMenuManager.default.leftMenuNavigationController {
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func handleShowSearchbar() {
        //        let vc = SearchViewController()
        //        vc.callbackOpenBoard = { [weak self] boardBlock in
        //            self?.sideMenuViewController.setBoardSelected(boardBlock: boardBlock)
        //        }
        //        vc.callbackNoteEdited = { [weak self] editorMode in
        //            self?.handleEditorMode(editorMode)
        //        }
        //        let navVC = MyNavigationController(rootViewController: vc)
        //        navVC.modalPresentationStyle = .overFullScreen
        //        navVC.modalTransitionStyle = .crossDissolve
        //        self.navigationController?.present(navVC, animated: true, completion: nil)
        
        let alert = UIAlertController(title: "Title", message: "Please Select an Option", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Approve", style: .default , handler:{ (UIAlertAction)in
            print("User click Approve button")
        }))
        
        alert.addAction(UIAlertAction(title: "Edit", style: .default , handler:{ (UIAlertAction)in
            print("User click Edit button")
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction)in
            print("User click Delete button")
        }))
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        
        
        //uncomment for iPad Support
        //alert.popoverPresentationController?.sourceView = self.view
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension HomeViewController {
    
    
    func createMenu() -> UIMenu {
        
        let photoAction = UIAction(
            title: "Camera",
            image: UIImage(systemName: "camera")
        ) { (_) in
            print("New Photo from Camera")
        }
        
        let albumAction = UIAction(
            title: "Photo Album",
            image: UIImage(systemName: "square.stack")
        ) { (_) in
            print("Photo from photo album")
        }
        
        let fromWebAction = UIAction(
            title: "From the Web",
            image: UIImage(systemName: "globe")
        ) { (_) in
            print("Photo from the internet")
        }
        
        let menuActions = [photoAction, albumAction, fromWebAction]
        
        let addNewMenu = UIMenu(
            title: "",
            children: menuActions)
        
        return addNewMenu
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
