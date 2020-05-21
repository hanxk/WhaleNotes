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
        notesView.delegate = self
        self.notesView = notesView
        self.view.addSubview(notesView)
            notesView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        self.setupFloatButtons()
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

// tableview
extension HomeViewController {
    
}

// float buttons
extension HomeViewController {
    
    func setupFloatButtons() {
        let btnNewNote = makeButton().then {
            $0.tintColor = .white
            $0.backgroundColor = .brand
            $0.setImage( UIImage(systemName: "square.and.pencil"), for: .normal)
            $0.addTarget(self, action: #selector(btnNewNoteTapped), for: .touchUpInside)
        }
        self.view.addSubview(btnNewNote)
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(52)
            make.bottom.equalTo(self.view).offset(-26)
            make.trailing.equalTo(self.view).offset(-15)
        }
        
        let btnMore = makeButton().then {
            $0.backgroundColor = .white
            $0.tintColor = .brand
            $0.setImage( UIImage(systemName: "ellipsis"), for: .normal)
            $0.addTarget(self, action: #selector(btnMoreTapped), for: .touchUpInside)
        }
        self.view.addSubview(btnMore)
        btnMore.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(52)
            make.bottom.equalTo(btnNewNote.snp.top).offset(-16)
            make.trailing.equalTo(btnNewNote)
        }
    }
    
    @objc func btnNewNoteTapped (sender:UIButton) {
        //        self.openNoteEditor(createMode: .text)
        self.openEditor(createMode: .text)
        
    }
    
    private func openNoteEditor(type: MenuType) {
        switch type {
        case .text:
            self.openEditor(createMode: .text)
        case .todo:
            self.openEditor(createMode: .todo)
        case .image:
            let viewController = TLPhotosPickerViewController()
            viewController.delegate = self
            var configure = TLPhotosPickerConfigure()
            configure.allowedVideo = false
            configure.allowedLivePhotos = false
            configure.allowedVideoRecording = false
            viewController.configure = configure
            self.present(viewController, animated: true, completion: nil)
        case .camera:
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .camera
            vc.mediaTypes = ["public.image"]
            present(vc, animated: true)
            break
        }
    }
    
    func openEditor(createMode: CreateMode) {
        if let note = notesView?.createNote(createMode: createMode) {
            openEditorVC(note: note,isEdit: true)
        }
    }
    
    func openEditorVC(note: Note,isEdit:Bool = false) {
        let noteVC  = EditorViewController()
        noteVC.note = note
        noteVC.isEdit = isEdit
        noteVC.callbackNoteUpdate = {updateMode in
            self.notesView?.noteEditorUpdated(mode: updateMode)
        }
        navigationController?.pushViewController(noteVC, animated: true)
    }
    
    @objc func btnMoreTapped (sender:UIButton) {
        let popMenuVC = PopBlocksViewController()
        popMenuVC.cellTapped = { [weak self] type in
            popMenuVC.dismiss(animated: true, completion: {
                self?.openNoteEditor(type:type)
            })
        }
        ContextMenu.shared.show(
            sourceViewController: self,
            viewController: popMenuVC,
            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
            sourceView: sender
        )
    }
    
    private func makeButton() -> UIButton {
        let btn = UIButton()
        btn.contentMode = .center
        btn.imageView?.contentMode = .scaleAspectFit
        let layer0 = btn.layer
        layer0.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 4
        layer0.shadowOffset = CGSize(width: 0, height: 2)
        layer0.cornerRadius = 26
        layer0.backgroundColor = UIColor(red: 0.278, green: 0.627, blue: 0.957, alpha: 1).cgColor
        return btn
    }
}


extension HomeViewController: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    func handlePicker(images: [TLPHAsset]) {
        self.showHud()
        Observable<[TLPHAsset]>.just(images)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(images)  -> [Block] in
                var imageBlocks:[Block] = []
                images.forEach {
                    if let image =  $0.fullResolutionImage?.fixedOrientation() {
                        let imageName =  $0.uuidName
                        let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
                        if success {
                            imageBlocks.append(Block.newImageBlock(imageUrl: imageName))
                        }
                    }
                }
                return imageBlocks
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                self.hideHUD()
                if let blocks  = $0.element {
                    self.openEditor(createMode: .attachment(blocks: blocks))
                }
        }
        .disposed(by: disposeBag)
    }
}


extension HomeViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {  return}
        self.handlePicker(image: image)
    }
    
    func handlePicker(image: UIImage) {
        self.showHud()
        Observable<UIImage>.just(image)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(image)  -> [Block] in
                let imageName = UUID().uuidString+".png"
                if let rightImage = image.fixedOrientation() {
                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
                    if success {
                        return [Block.newImageBlock(imageUrl: imageName)]
                    }
                }
                return []
            })
            .observeOn(MainScheduler.instance)
            .subscribe {
                self.hideHUD()
                if let blocks  = $0.element {
                    self.openEditor(createMode: .attachment(blocks: blocks))
                }
        }
        .disposed(by: disposeBag)
    }
}


extension HomeViewController: NotesViewDelegate {
    func didSelectItemAt(note: Note, indexPath: IndexPath) {
        self.openEditorVC(note: note)
    }
}
