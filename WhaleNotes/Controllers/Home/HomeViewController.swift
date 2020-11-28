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
    
    static let toolbarHeight:CGFloat = 54
    
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
        $0.tintColor = .iconColor
        let barAppearance =  UINavigationBarAppearance()
        barAppearance.configureWithDefaultBackground()
        $0.standardAppearance.backgroundColor = .bg
            
        $0.scrollEdgeAppearance = barAppearance
        $0.standardAppearance.shadowColor = nil
    }
    
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: HomeViewController.toolbarHeight)).then {
        $0.tintColor = .iconColor
//            $0.barTintColor = UIColor(hexString: "#EBECEF")
        $0.isTranslucent = false
        
//            $0.clipsToBounds = true
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
    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
////        self.navigationController?.navigationBar.barTintColor = .bg
//    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
}
class Toolbar: UIToolbar {

    let height: CGFloat = HomeViewController.toolbarHeight

    override func layoutSubviews() {
        super.layoutSubviews()

        var newBounds = self.bounds
        newBounds.size.height = height
        self.bounds = newBounds
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var size = super.sizeThatFits(size)
        size.height = height
        return size
    }
}

//MARK: tool bar
extension HomeViewController {
    
    enum ToolbarAction:Int {
        case Note = 0
        case Camera = 1
        case Photos = 2
        case Audio = 3
        case Bookmark = 4
    }
    
    private  func setupToolbar() {
        self.view.addSubview(toolbar)
        toolbar.snp.makeConstraints {
            $0.width.equalToSuperview()
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
//            $0.height.equalTo(HomeViewController.toolbarHeight)
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
        }
    }
    
    private func setupBoardToolbar() {
        var items = [UIBarButtonItem]()
        items.append(generateUIBarButtonItem(systemName:"camera",action: .camera))
        items.append(generateSpace())
        items.append(generateUIBarButtonItem(systemName:"photo.on.rectangle",action: .image))
        items.append(generateSpace())
        items.append(generateUIBarButtonItem(systemName:"mic",action: .text))
        items.append(generateSpace())
        items.append(generateUIBarButtonItem(systemName:"link",action: .text))
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        items.append(generateUIBarButtonItem(systemName:"square.and.pencil",action: .text,pointSize: 18))
        
        toolbar.tintColor = .iconColor
        toolbar.items = items
    }
    
    private func setupTrashToolbar() {
        var items = [UIBarButtonItem]()
        items.append(UIBarButtonItem(title: "全部恢复", style: .plain, target: self, action: #selector(trashRestoreTapped(sender:))))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        items.append(space)
        items.append(UIBarButtonItem(title: "全部删除", style: .plain, target: self, action: #selector(trashDeleteTapped(sender:))))
        toolbar.tintColor = .brand
        toolbar.items = items
    }
    
    
    private func generateUIBarButtonItem(systemName:String,action:MenuType,pointSize:CGFloat = 15) -> UIBarButtonItem {
        let icon = UIImage(systemName: systemName, pointSize: pointSize)
        let item = UIBarButtonItem(image:icon , style: .plain, target: self, action: #selector(toolbarActionTapped(sender:)))
        item.tag = action.rawValue
        item.imageInsets = UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0)
        return item
    }
    
    private func generateSpace() -> UIBarButtonItem {
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 14
        return space
    }
    
    
    @objc func toolbarActionTapped (sender: UIBarButtonItem) {
        guard let boardView = self.contentView as? BoardView,
             let toolbarAction = MenuType.init(rawValue: sender.tag) else{
            return
        }
        boardView.openNoteEditor(type: toolbarAction)
    }
    
    
    @objc func trashDeleteTapped (sender: UIBarButtonItem) {
        guard let trashView = self.contentView as? TrashView else{ return }
        trashView.handleClearTrash()
    }
    @objc func trashRestoreTapped (sender: UIBarButtonItem) {
        guard let trashView = self.contentView as? TrashView else{ return }
        trashView.handleRestoreTrash()
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
        self.setupBoardToolbar()
    
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
        
        let topPadding = self.topbarHeight
        let height:CGFloat = self.view.frame.height - topPadding
        let trashView = TrashView(frame: CGRect(x: 0, y: topPadding, width: self.view.frame.width, height: height),boardsMap:
                                    sideMenuViewController.boardsMap)
        self.contentView = trashView
        self.containerView.addSubview(trashView)
        trashView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.setupTrashToolbar()
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
//        button.backgroundColor = .red
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
        let vc = SearchViewController()
        vc.boardsMap = sideMenuViewController.boardsMap
//        vc.boards = boards
        
//        vc.callbackOpenBoard = { [weak self] boardBlock in
//            self?.sideMenuViewController.setBoardSelected(boardBlock: boardBlock)
//        }
//        vc.callbackNoteEdited = { [weak self] editorMode in
//            self?.handleEditorMode(editorMode)
//        }
        let navVC = MyNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .overFullScreen
        navVC.modalTransitionStyle = .crossDissolve
        self.navigationController?.present(navVC, animated: true, completion: nil)
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
