//
//  NotesView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import SnapKit
import AsyncDisplayKit
import TLPhotoPicker
import RxSwift
import Photos
import ContextMenu
import JXPhotoBrowser


//protocol NotesViewDelegate: AnyObject {
//    func didSelectItemAt(note:Note,indexPath: IndexPath)
//}

enum DisplayMode {
    case waterfall
    case grid
//    case list
}

protocol NotesViewDelegate:AnyObject {
    func embeddedBlockTapped(block:Block)
}

class NotesView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    
    private let usecase = NotesUseCase()
    private let editorUseCase = NoteRepo()
    
    private var selectedIndexPath:IndexPath?
    private var sectionNoteInfo:SectionNoteInfo!
    
    var delegate:NotesViewDelegate?
    
    var board:Board! {
        didSet {
            self.setupData()
        }
    }
    
    enum NotesViewConstants {
        static let cellSpace: CGFloat = 12
        static let cellHorizontalSpace: CGFloat = 16
        
        
        static let waterfall_cellSpace: CGFloat = 12
        static let waterfall_cellHorizontalSpace: CGFloat = 14
    }
    
    
    private var numberOfColumns:CGFloat = 2
    
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns), columnSpacing:  NotesViewConstants.waterfall_cellSpace, interItemSpacing: NotesViewConstants.waterfall_cellSpace, sectionInsets: UIEdgeInsets(top: 12, left: NotesViewConstants.waterfall_cellHorizontalSpace, bottom: 12, right:  NotesViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
    }
    
    
    private lazy var collectionLayout =  UICollectionViewFlowLayout().then {
        
        let validWidth = UIScreen.main.bounds.width - NotesViewConstants.cellHorizontalSpace*2 - NotesViewConstants.cellSpace*CGFloat(numberOfColumns-1)
        let itemWidth = validWidth / numberOfColumns
        
        $0.itemSize = CGSize(width: itemWidth, height: 214)
        $0.minimumInteritemSpacing = NotesViewConstants.cellSpace
        $0.minimumLineSpacing = NotesViewConstants.cellSpace
    }
    
    private var mode:DisplayMode = .grid
    private(set) lazy var collectionNode = self.generateCollectionView(mode: mode)
    
    
    func generateCollectionView(mode:DisplayMode) -> ASCollectionNode {
        switch mode {
        case .waterfall:
            return ASCollectionNode(layoutDelegate: layoutDelegate, layoutFacilitator: nil).then { [weak self] in
                    guard let self = self else {return}
                    $0.alwaysBounceVertical = true
                    let _layoutInspector = layoutDelegate
                    $0.dataSource = self
                    $0.delegate = self
                    $0.layoutInspector = _layoutInspector
                    $0.contentInset = UIEdgeInsets(top: 6, left: NotesViewConstants.cellHorizontalSpace, bottom: 160, right: NotesViewConstants.cellHorizontalSpace)
                    $0.showsVerticalScrollIndicator = false
                    
                }
        case .grid:
            return ASCollectionNode(collectionViewLayout:collectionLayout).then { [weak self] in
                    guard let self = self else {return}
                    $0.alwaysBounceVertical = true
                    $0.dataSource = self
                    $0.delegate = self
                    $0.contentInset = UIEdgeInsets(top: 12, left: NotesViewConstants.cellHorizontalSpace, bottom: 160, right: NotesViewConstants.cellHorizontalSpace)
                    $0.showsVerticalScrollIndicator = false
                    
                }
        }
    }
    
    
    
    private var noteInfos:[Note] {
        if sectionNoteInfo == nil {
            return []
        }
        
        return sectionNoteInfo.notes
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        
        self.setupUI()
    }
    
    private func setupUI() {
        collectionNode.frame = self.frame
        collectionNode.backgroundColor = .clear
        self.addSubnode(collectionNode)
        self.setupFloatButtons()
    }
    
    private func setupData() {
        BoardRepo.shared.getSectionNoteInfos(boardId: board.id)
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    self.sectionNoteInfo = $0[0]
                    self.collectionNode.reloadData()
                }
            }, onError: {
                Logger.error($0)
            })
        .disposed(by: disposeBag)
    }
    
}

extension NotesView {
    
    func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    func viewWillDisappear(_ animated: Bool) {
        //        notesToken?.invalidate()
    }
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
        //
        switch mode {
        case .insert(let noteInfo):
            sectionNoteInfo.notes.insert(noteInfo, at: 0)
            self.collectionNode.performBatchUpdates({
                self.collectionNode.insertItems(at: [IndexPath(row: 0, section: 0)])
            }, completion: nil)
        case .update(let noteInfo):
            if let row = noteInfos.firstIndex(where: { $0.rootBlock.id == noteInfo.rootBlock.id }) {
               sectionNoteInfo.notes[row] = noteInfo
                self.collectionNode.performBatchUpdates({
                    self.collectionNode.reloadItems(at: [IndexPath(row: row, section: 0)])
                }, completion: nil)
            }
        case .delete(let noteInfo):
            if let row = noteInfos.firstIndex(where: { $0.rootBlock.id == noteInfo.rootBlock.id }) {
                sectionNoteInfo.notes.remove(at: row)
                self.collectionNode.performBatchUpdates({
                    self.collectionNode.deleteItems(at: [IndexPath(row: row, section: 0)])
                }, completion: nil)
            }
        }
    }
}

extension NotesView {
    
    private func createNewNote(createMode: CreateMode,callback: @escaping (Note)->Void) {
        let blockTypes = generateNewNoteBlockTypes(createMode: createMode)
        editorUseCase.createNewNote(sectionId: self.sectionNoteInfo.section.id, blockTypes: blockTypes)
            .subscribe(onNext: {
                 callback($0)
            }, onError: {
                Logger.error($0)
            })
        .disposed(by: disposeBag)
    }
    
    fileprivate func generateNewNoteBlockTypes(createMode: CreateMode) -> [BlockType]{
        
        var blockTypes:[BlockType] = []
        switch createMode {
        case .text:
            blockTypes.append(BlockType.text)
            break
        case .todo:
            blockTypes.append(BlockType.todo)
            break
        case .images:
            break
        }
        return blockTypes
    }
    
}


extension NotesView: ASCollectionDataSource {
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.noteInfos.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let noteInfo = self.noteInfos[indexPath.row]
        let itemSize = self.collectionLayout.itemSize
        return {
            let node =  NoteCellNode(noteInfo: noteInfo,itemSize: itemSize)
            node.delegate = self
            return node
        }
    }
}

extension NotesView:NoteCellNodeDelegate {
    func noteCellImageBlockTapped(imageView: ASImageNode, blocks: [Block], index: Int) {
        
        let defaultImage: UIImage = imageView.image!
        
        let browser = PhotoViewerViewController(blocks: blocks)
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            imageView.image = defaultImage
            return imageView.view
        })
        browser.show()
    }
    
    
    func noteCellBlockTapped(block: Block) {
        
    }
    
    func noteCellMenuTapped(sender: UIView) {
    }
}



extension NotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let note = self.noteInfos[indexPath.row]
        self.openEditorVC(note: note)
    }
}

// float buttons
extension NotesView {
    
    func setupFloatButtons() {
        
        let btnSize:CGFloat = 54
        
        let btnNewNote = makeButton().then {
            $0.tintColor = .white
            $0.backgroundColor = .brand

            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            $0.setImage(UIImage(systemName: "pencil",withConfiguration:config )?.withTintColor(.white), for: .normal)
            $0.addTarget(self, action: #selector(btnNewNoteTapped), for: .touchUpInside)
        }
        self.addSubview(btnNewNote)
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(btnSize)
            make.bottom.equalTo(self).offset(-22)
            make.trailing.equalTo(self).offset(-15)
        }
        
        let btnMore = makeButton().then {
            $0.backgroundColor = .white
            $0.tintColor = .brand
            $0.setImage( UIImage(systemName: "ellipsis"), for: .normal)
            $0.addTarget(self, action: #selector(btnMoreTapped), for: .touchUpInside)
        }
        self.addSubview(btnMore)
        btnMore.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(btnSize)
            make.bottom.equalTo(btnNewNote.snp.top).offset(-16)
            make.trailing.equalTo(btnNewNote)
        }
    }
    
    @objc func btnNewNoteTapped (sender:UIButton) {
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
            configure.doneTitle = "完成"
            configure.cancelTitle="取消"
            configure.allowedLivePhotos = false
            configure.allowedVideoRecording = false
            viewController.configure = configure
            self.controller?.present(viewController, animated: true, completion: nil)
        case .camera:
            let vc = UIImagePickerController()
            vc.delegate = self
            vc.sourceType = .camera
            vc.mediaTypes = ["public.image"]
            self.controller?.present(vc, animated: true)
            break
        }
    }
    
    func openEditor(createMode: CreateMode) {
        createNewNote(createMode: createMode) { [weak self] in
            self?.openEditorVC(note:$0, isNew: true)
        }
    }
    
    func openEditorVC(note: Note,isNew:Bool = false) {
        let noteVC  = EditorViewController()
        noteVC.mode = isNew ? EditorMode.create(noteInfo: note) :  EditorMode.browser(noteInfo: note)
        noteVC.callbackNoteUpdate = {updateMode in
            self.noteEditorUpdated(mode: updateMode)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
    @objc func btnMoreTapped (sender:UIButton) {
//        let popMenuVC = PopBlocksViewController()
//        popMenuVC.isFromHome = true
//        popMenuVC.cellTapped = { [weak self] type in
//            popMenuVC.dismiss(animated: true, completion: {
//                self?.openNoteEditor(type:type)
//            })
//        }
//        ContextMenu.shared.show(
//            sourceViewController: self.controller!,
//            viewController: popMenuVC,
//            options: ContextMenu.Options(containerStyle: ContextMenu.ContainerStyle(overlayColor: UIColor.black.withAlphaComponent(0.2))),
//            sourceView: sender
//        )
        NotesView.showNotesMenu(sourceView: sender, sourceVC: self.controller!) { [weak self]  menuType in
              self?.openNoteEditor(type:menuType)
        }
    }
    
    static func showNotesMenu(sourceView: UIView,sourceVC:UIViewController,callback: @escaping (MenuType)->Void) {
        let items = [
            ContextMenuItem(label: "文本", icon: "textbox", tag: MenuType.text),
            ContextMenuItem(label: "待办事项", icon: "checkmark.square", tag: MenuType.todo),
            ContextMenuItem(label: "相册", icon: "photo.on.rectangle", tag: MenuType.image),
            ContextMenuItem(label: "拍照", icon: "camera", tag: MenuType.camera),
        ]
        ContextMenuViewController.show(sourceView:sourceView, sourceVC: sourceVC, items: items) {
            if let menuType = $0.tag as? MenuType {
                callback(menuType)
            }
        }
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


extension NotesView: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    
    func handlePicker(images: [TLPHAsset]) {
        self.controller?.showHud()
        createNewNote(createMode: .images(blocks: [])) { [weak self] in
            self?.createImageBlocksAndOpen(noteInfo:$0, images: images)
        }
    }
    
    private func createImageBlocksAndOpen(noteInfo:Note,images: [TLPHAsset]) {
        editorUseCase.createImageBlocks(noteId: noteInfo.id, images: images, success: { [weak self] imageBlocks in
            if let self = self {
                self.controller?.hideHUD()
                var newNoteInfo = noteInfo
                newNoteInfo.addImageBlocks(imageBlocks)
                self.openEditorVC(note:newNoteInfo, isNew: true)
            }
        }) { [weak self]  in
            self?.controller?.hideHUD()
        }
    }
}


extension NotesView: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {  return}
        self.handlePicker(image: image)
    }
    
    func handlePicker(image: UIImage) {
        self.controller?.showHud()
        createNewNote(createMode: .images(blocks: [])) { [weak self] in
            self?.createImageBlocksAndOpen(noteInfo:$0, image: image)
        }
    }
    private func createImageBlocksAndOpen(noteInfo:Note,image:UIImage) {
        editorUseCase.createImageBlocks(noteId: noteInfo.id, image: image, success: { [weak self] imageBlock in
            if let self = self {
                self.controller?.hideHUD()
                var newNoteInfo = noteInfo
                newNoteInfo.addImageBlocks([imageBlock])
                self.openEditorVC(note:newNoteInfo, isNew: true)
            }
        }) { [weak self]  in
            self?.controller?.hideHUD()
        }
    }
}


struct MenuItem  {
    var label: String
    var icon: String
    var type: MenuType
}

enum MenuType {
    case text
    case image
    case camera
    case todo
}