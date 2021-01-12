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
    
    static let toolbarHeight:CGFloat = 120
    
    private var contentView:NotesListView!
    private var floatButton:UIButton!
    
    private lazy var myNavbar:UINavigationBar = UINavigationBar() .then{
        $0.delegate = self
        $0.tintColor = .iconColor
        $0.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(hexString: "#333333")]
        $0.transparentNavigationBar()
    }
    
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: HomeViewController.toolbarHeight)).then {
        $0.tintColor = .iconColor
        $0.isTranslucent = false
    }
    
    private var trashFloatButton:UIButton?
    private var newNoteFloatButton:UIButton?
  
    override var title: String? {
        didSet {
            myNavbar.topItem?.title = title
        }
    }
    
    private var containerView:UIView = UIView()
    
    private let titleButton:HomeTitleView = HomeTitleView()
    private let actionView:HomeActionView = HomeActionView()
    
    
    private lazy var sideMenuViewController = SideMenuViewController().then {
        $0.delegate = self
    }
    
    var mode:NoteListMode? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    
    private func setup() {
        
        self.setupNavgationBar()
        self.setupSideMenu()
        self.setupToolbar()
        self.setupNoteListView()
        
//        self.extendedLayoutIncludesOpaqueBars = true
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
//            switch self.sideMenuItemType {
//            case .board(let board):
//                openBoardSetting(board: board)
//                break
//            case .system(let menuInfo):
//                if case .board(let board) = menuInfo {
//                    openBoardSetting(board: board)
//                }
//                break
//            case .none:
//                break
//            }
        }
    }
    
    func setupNoteListView() {
        let topPadding = self.topbarHeight + 4
        let noteListView = NotesListView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        noteListView.tableView.contentInset = UIEdgeInsets(top: topPadding, left: 0, bottom: 120, right: 0)
        noteListView.tableView.view.scrollIndicatorInsets = UIEdgeInsets(top: topPadding, left: 0, bottom: 0, right: 0)
        self.containerView.addSubview(noteListView)
        self.contentView = noteListView
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
//        self.view.addSubview(toolbar)
//        toolbar.snp.makeConstraints {
//            $0.width.equalToSuperview()
//            $0.left.equalToSuperview()
//            $0.right.equalToSuperview()
////            $0.height.equalTo(HomeViewController.toolbarHeight)
//            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin)
//        }
        
//        self.view.addSubview(actionView)
//        actionView.snp.makeConstraints {
//            $0.width.equalTo(HomeActionView.SizeConstants.adButtonWidth+HomeActionView.SizeConstants.menuButtonWidth)
//            $0.height.equalTo(HomeActionView.SizeConstants.height)
//            $0.centerX.equalToSuperview()
//            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-20)
//        }
//        actionView.noteButton.addTarget(self, action: #selector(noteButtonTapped), for: .touchUpInside)
    }
    
    private func setupBoardToolbar() {
        var items = [UIBarButtonItem]()
        
        let menuImg = UIImage(named: "ico_menu")?.withTintColor(UIColor.iconColor)
        let item = UIBarButtonItem(image:menuImg , style: .plain, target: self, action: #selector(toggleSideMenu))
        items.append(item)
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        items.append(space)
        
        
        let searchItem = UIBarButtonItem(image:UIImage(systemName: "magnifyingglass") , style: .plain, target: self, action: #selector(handleShowSearchbar))
        items.append(searchItem)
        
//        items.append(generateUIBarButtonItem(systemName:"camera",action: .camera))
//        items.append(generateSpace())
//        items.append(generateUIBarButtonItem(systemName:"photo.on.rectangle",action: .image))
//        items.append(generateSpace())
//        items.append(generateUIBarButtonItem(systemName:"mic",action: .text))
//        items.append(generateSpace())
//        items.append(generateUIBarButtonItem(systemName:"link",action: .bookmark))
//        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
//        items.append(generateUIBarButtonItem(systemName:"square.and.pencil",action: .text,pointSize: 16))
        
        toolbar.tintColor = .iconColor
        toolbar.items = items
    }
    
    
    @objc func toggleSideMenu () {
        if let vc = SideMenuManager.default.leftMenuNavigationController {
            present(vc, animated: true, completion: nil)
        }
    }
    
    
    @objc func handleShowSearchbar() {
//        let vc = SearchViewController()
//        vc.boardsMap = sideMenuViewController.boardsMap
//        let navVC = MyNavigationController(rootViewController: vc)
//        navVC.modalPresentationStyle = .overFullScreen
//        navVC.modalTransitionStyle = .crossDissolve
//        self.navigationController?.present(navVC, animated: true, completion: nil)
    }
}


//MARK: board edited
extension HomeViewController {
    private func handleBoardUpdated(board:BlockInfo) {
//        self.sideMenuItemType = SideMenuItem.board(board: board)
//        let properties = board.blockBoardProperties!
//        self.title = board.title
        
//        navBar.topItem?.title = board.title
//        navItem.title = board.title
    }
    
    private func handleBoardDeleted(board:BlockInfo) {
    }
}

//MARK: content view
extension HomeViewController {
    
    func setupContentView(tag:Tag) {
        titleButton.setTitle(tag.title, icon: nil)
        self.setupTagListView(mode: .tag(tag: tag))
    }
    
    func setupContentView(systemMenu:SystemMenuItem) {
        titleButton.setTitle(systemMenu.title, icon: nil)
        switch systemMenu {
        case .all:
            self.setupTagListView(mode: .all)
            break
        case .trash:
            self.setupTagListView(mode: .trash)
            break
        }
    }
    
    func setupTagListView(mode:NoteListMode) {
        self.mode = mode
        contentView.loadData(mode: mode)
        self.setupFloatButton(mode: mode)
    }
}

//MARK: nav bar
extension HomeViewController:UINavigationBarDelegate{
    
    private func setupUIFrame(){
        self.view.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.height.width.equalToSuperview()
        }
        self.view.addSubview(myNavbar)
        myNavbar.snp.makeConstraints {
            $0.width.equalToSuperview()
//            $0.height.equalTo(HomeViewController.toolbarHeight)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin)
        }
        self.navigationController?.navigationBar.isHidden = true
    }
    
    private func setupNavgationBar() {
        self.setupUIFrame()
        
        let navItem = UINavigationItem()
        myNavbar.items = [navItem]
        
        let button =  UIButton().then {
            $0.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            $0.contentHorizontalAlignment = .leading
            $0.setImage(UIImage(named: "ico_menu")?.withTintColor(UIColor.iconColor), for: .normal)
            $0.addTarget(self, action: #selector(toggleSideMenu), for: .touchUpInside)
        }
//        titleButton.backgroundColor = .blue
        let barButton = UIBarButtonItem(customView: button)
        navItem.leftBarButtonItem = barButton
//        button.backgroundColor = .red
//        let barButton = UIBarButtonItem(customView: button)
        
//        let label = UILabel()
//        label.textColor = UIColor.white
//        label.text = "TCO_choose_reminder";
//
        navItem.titleView = titleButton
        
//
//        if let titleView = self.navigationItem.titleView  {
//            titleView.snp.makeConstraints {
//                $0.left.equalToSuperview()
//                $0.height.equalToSuperview()
//            }
//        }
        let menuImg = UIImage(systemName: "magnifyingglass")?.withTintColor(UIColor.iconColor)
        let item = UIBarButtonItem(image:menuImg , style: .plain, target: self, action: #selector(handleShowSearchbar))
        navItem.rightBarButtonItems = [item]
        
        // status bar
        let window = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
          let statusBarFrame = window?.windowScene?.statusBarManager?.statusBarFrame

          let statusBarView = UIView(frame: statusBarFrame!)
          self.view.addSubview(statusBarView)
          statusBarView.backgroundColor = .statusbar
    }
    
    
//    func position(for bar: UIBarPositioning) -> UIBarPosition {
//        return .topAttached
//    }
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
        settings.menuWidth = view.frame.width * 0.8
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
            SideMenuManager.default.addScreenEdgePanGesturesToPresent(toView: navigationController.view,forMenu: .left)
        }
    }
}

extension HomeViewController: SideMenuViewControllerDelegate {
    func sideMenuItemSelected(sideMenuItem: SystemMenuItem) {
        self.setupContentView(systemMenu: sideMenuItem)
    }
    
    func sideMenuItemSelected(tag: Tag) {
        self.setupContentView(tag: tag)
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

//MARK: float button
extension HomeViewController  {
    
    func setupFloatButton(mode:NoteListMode) {
        switch mode {
        case .trash:
            if self.trashFloatButton == nil {
                self.trashFloatButton =  self.generateFloatButton(background: UIColor(hexString: "#DD4C4F"), iconName: "xmark.bin", imageSize: 20)
                return
            }
            self.newNoteFloatButton?.isHidden  = true
            self.trashFloatButton?.isHidden  = false
        default:
            if self.newNoteFloatButton == nil {
                self.newNoteFloatButton =  self.generateFloatButton(background: UIColor.brand, iconName: "plus", imageSize: 22)
                return
            }
            self.trashFloatButton?.isHidden  = true
            self.newNoteFloatButton?.isHidden  = false
        }
    }
    
    func generateFloatButton(background:UIColor,iconName:String,imageSize: CGFloat) -> UIButton   {
        let btnNewNote = ActionButton().then {
            $0.contentMode = .center
            $0.adjustsImageWhenHighlighted = false
            let layer0 = $0.layer
            
            layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
            layer0.shadowOpacity = 1
            layer0.shadowRadius = 2
            layer0.shadowOffset = CGSize(width: 1, height: 2)
            
            $0.backgroundColor = background
            $0.tintColor = .white
            $0.layer.cornerRadius = FloatButtonConstants.btnSize / 2
            
            $0.setImage( UIImage(systemName: iconName, pointSize: imageSize, weight: .medium), for: .normal)

        }
        
        self.view.addSubview(btnNewNote)
        
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(FloatButtonConstants.btnSize)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-FloatButtonConstants.bottom)
            make.trailing.equalTo(self.view).offset(-FloatButtonConstants.trailing)
        }
        btnNewNote.addTarget(self, action: #selector(floatButtonTapped), for: .touchUpInside)
        return btnNewNote
    }
    
    
    @objc func floatButtonTapped()   {
        let mode = self.mode!
        switch mode {
        case .trash:
            contentView.clearTrash()
        default:
            contentView.createNewNote()
        }
    }
    
}
