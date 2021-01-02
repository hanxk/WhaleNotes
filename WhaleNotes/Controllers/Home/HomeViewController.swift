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
    
    private var contentView:UIView?
//    private var sideMenuItem:SideMenuItem! {
//        didSet {
//            if oldValue == sideMenuItem {
//                return
//            }
//            self.setupContentView()
//        }
//    }
    private lazy var myNavbar:UINavigationBar = UINavigationBar() .then{
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
        $0.isTranslucent = false
    }
  
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        
//        let editorVC = MDEditorSimpleViewController()
//        self.navigationController?.pushViewController(editorVC, animated: true)
    }
    
    
    private func setup() {
        
        self.setupNavgationBar()
        self.setupSideMenu()
        self.setupToolbar()
        self.settupNewNoteButton()
//        self.setupActionView()
        
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

//MARK: action float view
extension HomeViewController {
    
//    private  func setupActionView() {
//        self.view.addSubview(actionView)
//        actionView.snp.makeConstraints {
//            $0.width.equalTo(HomeActionView.SizeConstants.adButtonWidth+HomeActionView.SizeConstants.menuButtonWidth)
//            $0.height.equalTo(HomeActionView.SizeConstants.height)
//            $0.centerX.equalToSuperview()
//            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-20)
//        }
//        actionView.noteButton.addTarget(self, action: #selector(noteButtonTapped), for: .touchUpInside)
//        actionView.menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
//    }
    
   @objc func menuButtonTapped() {
        let actions:[UIControlMenuAction] = [
            UIControlMenuAction(title: "拍照", imageName:  "camera", handler: { _ in
                self.handleAction(.camera)
            }),
            UIControlMenuAction(title: "照片", imageName: "photo.on.rectangle", handler: { _ in
                self.handleAction(.image)
            }),
            UIControlMenuAction(title: "链接", imageName: "link", handler: { _ in
                self.handleAction(.bookmark)
            })
        ]

        let vc = MenuController(actions: actions)
        vc.title = "添加"
        self.present(vc, animated: true, completion: nil)
    }
    
    func handleAction(_ type:MenuType)  {
        guard let boardView = self.contentView as? BoardView else{
            return
        }
        boardView.openNoteEditor(type: type)
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
        self.setupTagListView(tag: tag)
    }
    
    func setupContentView(systemMenu:SystemMenuItem) {
        titleButton.setTitle(systemMenu.title, icon: nil)
        switch systemMenu {
        case .all:
            self.setupTagListView()
            break
        case .trash:
            break
        }
    }
    
    func setupTagListView(tag:Tag? = nil) {
        let tagListView:NotesListView
        if let contentView =  self.contentView as? NotesListView {
            tagListView = contentView
        }else {
            let topPadding = self.topbarHeight
            let height:CGFloat = self.view.frame.height - topPadding
            tagListView = NotesListView(frame: CGRect(x: 0, y: topPadding, width: self.view.frame.width, height: height))
            self.containerView.addSubview(tagListView)
            tagListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.contentView = tagListView
        }
        tagListView.loadData(tag:tag)
    }
    
    
//    func setupTrashView() {
//        if let oldView =  self.contentView {
//            oldView.removeFromSuperview()
//        }
//
//        let topPadding = self.topbarHeight
//        let height:CGFloat = self.view.frame.height - topPadding
//        let trashView = TrashView(frame: CGRect(x: 0, y: topPadding, width: self.view.frame.width, height: height),boardsMap:
//                                    sideMenuViewController.boardsMap)
//        self.contentView = trashView
//        self.containerView.addSubview(trashView)
//        trashView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//
//        self.setupTrashToolbar()
//    }
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
    func settupNewNoteButton()  {
        let btnNewNote = NotesView.makeFloatButton().then {
            $0.backgroundColor = .brand
            $0.tintColor = .white
            $0.layer.cornerRadius = FloatButtonConstants.btnSize / 2
            $0.setImage( UIImage(systemName: "plus", pointSize: 22, weight: .medium), for: .normal)
//            $0.setImage( UIImage(systemName: "square.and.pencil", pointSize: FloatButtonConstants.iconSize, weight: .light), for: .normal)
            $0.addTarget(self, action: #selector(btnNewNoteTapped), for: .touchUpInside)
        }
        self.view.addSubview(btnNewNote)
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(FloatButtonConstants.btnSize)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-FloatButtonConstants.bottom)
            make.trailing.equalTo(self.view).offset(-FloatButtonConstants.trailing)
        }
    }
    
    @objc func btnNewNoteTapped()   {
        guard let boardView = self.contentView as? NotesListView else{
            return
        }
        boardView.createNewNote()
    }
}
