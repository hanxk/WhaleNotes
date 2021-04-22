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


enum FloatButtonConstants {
    static let btnSize:CGFloat = 54
    static let trailing:CGFloat = 16
    static let bottom:CGFloat = 16
    static let iconSize:CGFloat = 20
}

class HomeViewController: UIViewController, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    
    //    static let toolbarHeight:CGFloat = 120
    
    private var contentView:NotesListView!
    private var floatButton:UIButton!
    
    private lazy var myNavbar:UINavigationBar = UINavigationBar() .then{
        $0.delegate = self
        $0.tintColor = .iconColor
        $0.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor(hexString: "#333333")]
        //        $0.transparentNavigationBar()
    }
    
    let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0)).then {
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
        
        NotesSyncEngine.shared.setup()
        
//        CloudModel.currentModel.refresh { error in
//            if let error = error {
//              let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
//              alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//              self.present(alert, animated: true, completion: nil)
////              self.tableView.refreshControl?.endRefreshing()
//              return
//            }
//            print(CloudModel.currentModel.notes)
////            self.tableView.refreshControl?.endRefreshing()
////            self.reloadSnapshot(animated: true)
//        }
    }
    
    
    private func setup() {
        
        self.setupNavgationBar()
        self.setupSideMenu()
        self.setupToolbar()
        self.setupNoteListView()
        
        //        self.extendedLayoutIncludesOpaqueBars = true
        self.view.backgroundColor = .bg
        
        func openBoardSetting(board: BlockInfo) {
            
        }
        
        titleButton.callbackTapped = {
            guard let mode = self.mode else { return }
            if case .tag(let tag) = mode {
                self.handleTagMenuAction(tag: tag)
            }
        }
        
        self.deleteUnusedTags()
    }
    
    
    
    func setupNoteListView() {
        self.containerView.removeSubviews()
        let noteListView = NotesListView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)).then {
            let topPadding:CGFloat = self.toolbarHeight  + NotesListViewConstants.topPadding
            //            let topPadding:CGFloat = 60
            $0.tableView.contentInset = UIEdgeInsets(top: topPadding, left: 0, bottom: NotesListViewConstants.bottomPadding+50, right: 0)
            //            $0.tableView.backgroundColor = .red
            $0.tableView.view.scrollIndicatorInsets = UIEdgeInsets(top: topPadding, left: 0, bottom: 0, right: 0)
        }
        self.containerView.addSubview(noteListView)
        self.contentView = noteListView
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}


//MARK: tag menu
extension HomeViewController  {
    
    fileprivate func handleTagMenuAction(tag:Tag) {
        let menuRows = [
            PopMenuRow(icon: UIImage(systemName: "pencil"), title: "编辑名称",tag:1),
            PopMenuRow(icon: UIImage(systemName: "grid"), title: "编辑图标",tag:2),
            PopMenuRow(icon: UIImage(systemName: "trash"), title: "删除",tag:3,isDestroy: true)
        ]
        let menuVC = PopMenuController(menuRows: menuRows)
        menuVC.rowSelected = {[weak self] menuRow in
            guard let tag = self?.mode?.tag else { return}
            let flag = menuRow.tag
            if flag == 1 {
                self?.showAlertTextField(title: "编辑名称", text: tag.title, placeholder: "", positiveBtnText: "更新", callbackPositive: { title in
                    //                    tag.title = title
                    var newTitle = title.trimmingCharacters(in: .whitespaces)
                    if newTitle.isEmpty { return }
                    //                    if newTitle.contains(" ") {
                    //                        newTitle += "# "
                    //                    }
                    self?.updateTagTitle(tag: tag, newTagTitle: title)
                })
            }else if flag == 2 {
                self?.openEmojiVC()
            }else if flag == 3 {
                self?.handleDelTag(tag: tag)
            }
        }
        menuVC.showModal(vc: self)
    }
    
    func openEmojiVC() {
        let vc = EmojiViewController()
        vc.callbackEmojiSelected = { [weak self] emoji in
            //            guard let self = self else { return }
            //            self.boardProperties.icon = emoji.value
            //            iconView.iconImage = self.boardProperties.getBoardIcon(fontSize: 50)
            self?.handleEmojiSelected(emoji.value)
        }
        let navVC = MyNavigationController(rootViewController: vc)
        navVC.modalPresentationStyle = .overFullScreen
        navVC.modalTransitionStyle = .coverVertical
        
        self.navigationController?.present(navVC, animated: true, completion: nil)
        
        //        self.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
        //        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func handleEmojiSelected(_ emoji:String) {
        guard var tag = self.mode?.tag else { return}
        tag.icon = emoji
        self.updateTag(tag: tag) {
            self.updateTagDatasource(tag: tag)
        }
    }
    
    func handleDelTag(tag: Tag) {
        let alert = UIAlertController(title: "", message: "当前标签及子标签将会被删除。确认要删除吗？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "确认删除", style: .destructive , handler:{ (UIAlertAction)in
            self.delteNotesTag(tag: tag)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:{ (UIAlertAction)in
            
        }))
        self.present(alert, animated: true, completion:nil)
    }
    
    func handleTagUpdated(_ tag:Tag) {
        self.updateTag(tag: tag) {
            self.updateTagDatasource(tag: tag)
        }
    }
    
    func updateTagDatasource(tag:Tag) {
        self.mode = NoteListMode.tag(tag: tag)
        titleButton.setTitle(tag.title, emoji: tag.icon)
        EventManager.shared.post(name:.Tag_CHANGED, object: tag, userInfo: nil)
        NotesSyncEngine.shared.pushLocalToRemote()
    }
    
    func updateTag(tag:Tag,callback: @escaping ()->Void) {
        NoteRepo.shared.updateTag(tag: tag)
            .subscribe(onNext: {
                callback()
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func updateTagTitle(tag:Tag,newTagTitle:String) {
        // 更新笔记的tag
        NoteRepo.shared.updateNotesTag(tag: tag, newTagTitle: newTagTitle)
            .subscribe(onNext: { [weak self] newTag in
                if let tag = newTag,
                   let self = self {
                    self.updateTagDatasource(tag: tag)
                    //刷新列表
                    self.contentView.loadData(mode: NoteListMode.tag(tag: tag))
                }
                
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func delteNotesTag(tag:Tag) {
        NoteRepo.shared.deleteNotesTag(tag: tag)
            .subscribe(onNext: { newTag in
                EventManager.shared.post(name: .Tag_DELETED)
                NotesSyncEngine.shared.pushLocalToRemote()
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
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
//        //        vc.boardsMap = sideMenuViewController.boardsMap
//        let navVC = MyNavigationController(rootViewController: vc)
//        navVC.modalPresentationStyle = .overFullScreen
//        navVC.modalTransitionStyle = .crossDissolve
//        self.navigationController?.present(navVC, animated: true, completion: nil)
    }
}


//MARK: content view
extension HomeViewController {
    
    func setupContentView(tag:Tag) {
        titleButton.setTitle(tag.title, emoji: tag.icon)
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
        if case .tag(let _) = mode {
            titleButton.isEnabled = true
        }else {
            titleButton.isEnabled = false
            
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
        self.view.addSubview(myNavbar)
        myNavbar.snp.makeConstraints {
            $0.width.equalToSuperview()
            //            $0.height.equalTo(HomeViewController.toolbarHeight)
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
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
        
        
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        let topInset: CGFloat = keyWindow?.safeAreaInsets.top ?? 44
        
        let statusBarFrame = CGRect(x: 0, y: 0, width: windowWidth, height: topInset)
        let statusBarView = UIView(frame: statusBarFrame)
        self.view.addSubview(statusBarView)
        statusBarView.backgroundColor = .statusbar
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
        presentationStyle.backgroundColor = .white
        //        presentationStyle.menuStartAlpha = CGFloat(menuAlphaSlider.value)
        //        presentationStyle.menuScaleFactor = CGFloat(menuScaleFactorSlider.value)
        //        presentationStyle.onTopShadowOpacity = shadowOpacitySlider.value
        presentationStyle.presentingEndAlpha = 0.5
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

//MARK
extension HomeViewController {
    func deleteUnusedTags() {
        NoteRepo.shared.deleteUnusedTags()
            .subscribe(onNext: {
                
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: float button
extension HomeViewController  {
    
    func setupFloatButton(mode:NoteListMode) {
        switch mode {
        case .trash:
            if self.trashFloatButton == nil {
                self.trashFloatButton =  self.generateFloatButton(background: UIColor(hexString: "#DD4C4F"), iconName: "xmark.bin", imageSize: 19)
                return
            }
            self.newNoteFloatButton?.isHidden  = true
            self.trashFloatButton?.isHidden  = false
        default:
            if self.newNoteFloatButton == nil {
                self.newNoteFloatButton =  self.generateFloatButton(background: UIColor.brand, iconName: "plus", imageSize: 21)
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
            
            if iconName == "plus" {
                layer0.shadowColor = UIColor(red: 0.957, green: 0.745, blue: 0.259, alpha: 0.4).cgColor
                $0.setImage( UIImage(systemName: iconName, pointSize: imageSize, weight: .medium), for: .normal)
                layer0.shadowColor = UIColor(red: 0.957, green: 0.745, blue: 0.259, alpha: 0.2).cgColor

                layer0.shadowOpacity = 1

                layer0.shadowRadius = 4

                layer0.shadowOffset = CGSize(width: 2, height: 2)
            }else {
                layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05).cgColor
                $0.setImage( UIImage(systemName: iconName, pointSize: imageSize, weight: .regular), for: .normal)
                layer0.shadowOpacity = 0
                layer0.shadowRadius = 3
                layer0.shadowOffset = CGSize(width: 2, height: 2)
            }
            
            $0.backgroundColor = background
            $0.tintColor = .white
            $0.layer.cornerRadius = FloatButtonConstants.btnSize / 2
            
            
        }
        
        self.view.addSubview(btnNewNote)
        
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(FloatButtonConstants.btnSize)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottomMargin).offset(-FloatButtonConstants.bottom)
//            make.trailing.equalTo(self.view).offset(-FloatButtonConstants.trailing)
            make.centerX.equalToSuperview()
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
