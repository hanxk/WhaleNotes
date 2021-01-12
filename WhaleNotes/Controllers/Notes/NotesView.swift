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

import SwiftLinkPreview
import FloatingPanel

//protocol NotesViewDelegate: AnyObject {
//    func didSelectItemAt(note:Note,indexPath: IndexPath)
//}

enum DisplayMode {
    case waterfall
    case grid
    //    case list
}

enum NotesViewConstants {
    static let cellSpace: CGFloat = 12
    static let cellVerticalSpace: CGFloat = 14
    static let cellHorizontalSpace: CGFloat = 14
    
    static let waterfall_cellSpace: CGFloat = 12
    static let waterfall_cellHorizontalSpace: CGFloat = 14
    
}


protocol NotesViewDelegate:AnyObject {
    func embeddedBlockTapped(block:Block)
}

class NotesView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    private var cards:[BlockInfo] = []
    var callbackSearchButtonTapped:((UIButton)->Void)!
    
    
    static func getItemSize(numberOfColumns:Int) -> CGSize {
        let validWidth = UIScreen.main.bounds.width - NotesViewConstants.cellHorizontalSpace * CGFloat(numberOfColumns) - NotesViewConstants.cellSpace*CGFloat(numberOfColumns-1)
        let itemWidth = validWidth / CGFloat(numberOfColumns)
        let itemHeight = itemWidth * 194 / 168
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    private var board:BlockInfo!
    private var noteStatus:NoteBlockStatus = NoteBlockStatus.normal
    
    private var numberOfColumns = 2
   
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns), columnSpacing:  NotesViewConstants.waterfall_cellSpace, interItemSpacing: NotesViewConstants.waterfall_cellSpace, sectionInsets: UIEdgeInsets(top: 12, left: NotesViewConstants.waterfall_cellHorizontalSpace, bottom: 12, right:  NotesViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
    }
    
    
    private lazy var toolbar = HomeToolbar().then {
        
        $0.callbackSearchButtonTapped = { sender in
            self.callbackSearchButtonTapped(sender)
        }
        
        $0.callbackAddButtonTapped = { _ in
            self.createTextNote()
        }
        
        $0.callbackMoreButtonTapped = { sender in
            NotesView.showNotesMenu(sourceView: sender, sourceVC: self.controller!,isIncludeText: false) { [weak self]  menuType in
                self?.openNoteEditor(type:menuType)
            }
        }
    }
    
    private var mode:DisplayMode = .grid
    private(set) lazy var collectionNode = self.generateCollectionView(mode: mode)
   
    func generateCollectionView(mode:DisplayMode) -> ASCollectionNode {
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
    }
    
    convenience init(frame: CGRect,board:BlockInfo,noteStatus:NoteBlockStatus = NoteBlockStatus.normal) {
        self.init(frame:frame)
        self.board = board
        self.noteStatus = noteStatus
        self.setupUI()
        self.setupData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    private func setupUI() {
        collectionNode.frame = self.frame
        collectionNode.backgroundColor = .bg
        self.addSubnode(collectionNode)
//        if noteStatus == NoteBlockStatus.normal {
//            self.setupFloatButtons()
//        }
    }
    
    private func setupData() {
//        NoteRepo.shared.queryNotes(boardId: self.board.id,noteStatus:  self.noteStatus)
//            .subscribe(onNext: { [weak self] in
//                if let self = self {
//                    self.noteInfos = $0
//                    self.collectionNode.reloadData()
//                }
//            }, onError: {
//                Logger.error($0)
//            })
//            .disposed(by: disposeBag)
        
    }
    
}

extension NotesView {
//    
//    private func createNewNote(noteBlock:Block,childBlock:Block,callback:((Note) -> Void)? = nil) {
//        //        self.createNewNote(noteBlock:noteBlock,childBlocks:[childBlock],callback:callback)
//    }
//    private func createNewNote(noteBlock:Block,childBlocks:[Block],callback:((Note) -> Void)? = nil) {
//        //        NoteRepo.shared.createNewNote(sectionId: self.sectionNoteInfo.section.id,noteBlock:noteBlock, childBlocks: childBlocks)
//        //            .subscribe { [weak self] note in
//        //                if let callback = callback {
//        //                    callback(note)
//        //                    return
//        //                }
//        //                self?.openEditorVC(note:note, isNew: true)
//        //            } onError: {
//        //                Logger.error($0)
//        //            }
//        //            .disposed(by: disposeBag)
//    }
    
}



//extension NotesView:NoteCellNodeDelegate {
//    func noteCellImageBlockTapped(imageView: ASImageNode, note: Note) {
//
//        let defaultImage: UIImage = imageView.image!
//        let browser = PhotoViewerViewController(note: note)
//        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
//            imageView.image = defaultImage
//            return imageView.view
//        })
//        browser.callBackShowNoteButtonTapped = {
//            if let noteIndex = self.noteInfos.firstIndex(where: {$0.id == note.id}) {
//                self.openEditorVC(note: self.noteInfos[noteIndex])
//            }
//        }
//        browser.show()
//    }
//
//    func noteCellImageBlockTapped(imageView: ASImageNode, blocks: [Block], index: Int) {
//
//    }
//
//
//    func noteCellBlockTapped(block: Block) {
//
//    }
//
//    func noteCellMenuTapped(sender: UIView,note:Note) {
//        //        NoteMenuViewController.show(mode: .list, note: note,sourceView: sender,delegate: self)
//    }
//}


extension NotesView: ASCollectionDataSource {
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        let count = self.cards.count
        if count == 0 {
            collectionNode.setEmptyMessage("暂无便签")
        }else {
            collectionNode.clearEmptyMessage()
        }
        return count
    }
    
//    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
//        let note = self.noteInfos[indexPath.row]
//        return {
//            let node =  NoteCellNode(note: note,itemSize: self.itemContentSize)
//            node.delegate = self
//            return node
//        }
//    }
    
}

extension NotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let cardBlock = self.cards[indexPath.row]
        self.openEditorVC(cardBlock: cardBlock)
    }
}

//MARK: CONTEXT MENU
extension NotesView: UICollectionViewDelegate{
    
//    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
//            return self.makeContextMenu(noteInfo: self.noteInfos[indexPath.row] )
//        })
//    }
    
//    func makeContextMenu(noteInfo:NoteInfo) -> UIMenu {
//        let menus =   NoteMenuViewController.generateNoteMenuItems(noteInfo: noteInfo).map { menuItem in
//            UIAction(title: menuItem.label, image: UIImage(systemName: menuItem.icon)) { action in
//                self.handleNoteInfoUpdate(noteInfo: noteInfo,menuType: menuItem.menuType)
//            }
//        }
//        return UIMenu(title: "", children: menus)
//    }
//
//    private func newNoteInfoModel(noteInfo:NoteInfo) -> NoteEidtorMenuModel {
//        let model = NoteEidtorMenuModel(model: noteInfo)
//        model.noteInfoPub.subscribe(onNext: { event in
//            self.handleNoteInfoEvent(event: event)
//        }).disposed(by: disposeBag)
//        return model
//    }
//
//
//    private func handleNoteInfoUpdate(noteInfo:NoteInfo,menuType:NoteEditorAction) {
//
//        let model = newNoteInfoModel(noteInfo: noteInfo)
//
//        switch menuType {
//        case .pin:
//            break
//        case .archive:
//            model.update(status: .archive)
//            break
//        case .move:
//            self.openChooseBoardVC(noteInfo: noteInfo, model: model)
//            break
//        case .background:
//            self.openChooseBackgroundVC(noteInfo: noteInfo,model: model)
//            break
//        case .trash:
//            model.update(status: .trash)
//            break
//        case .deleteBlock:
//            break
//        case .restore:
//            model.update(status: .normal)
//            break
//        case .delete:
//            break
//        }
//    }
//
//    private func handleNoteInfoEvent(event:EditorUpdateEvent) {
//        switch event {
//        case .statusChanged(noteInfo: let noteInfo):
//            self.handleDeleteNote(noteInfo)
//        case .backgroundChanged(noteInfo: let noteInfo):
//            self.handleUpdateNote(noteInfo)
//        case .delete(noteInfo: let noteInfo):
//            self.handleDeleteNote(noteInfo)
//        case .updated(noteInfo: let noteInfo):
//            self.handleUpdateNote(noteInfo)
//        case .moved(noteInfo: let noteInfo, _):
//            self.handleDeleteNote(noteInfo)
//        }
//    }
//
//
//    func handleUpdateNote(_ noteInfo:NoteInfo) {
//        if let row = noteInfos.firstIndex(where: { $0.id == noteInfo.id }) {
//            self.noteInfos[row] = noteInfo
//            self.collectionNode.performBatchUpdates({
//                self.collectionNode.reloadItems(at: [IndexPath(row: row, section: 0)])
//            }, completion: nil)
//        }
//    }
//
//    func handleDeleteNote(_ note:NoteInfo) {
//        if let row = noteInfos.firstIndex(where: { $0.id == note.id }) {
//            noteInfos.remove(at: row)
//            self.collectionNode.performBatchUpdates({
//                self.collectionNode.deleteItems(at: [IndexPath(row: row, section: 0)])
//            }, completion:nil)
//        }
//    }
//
//    private func openChooseBoardVC(noteInfo:NoteInfo,model:NoteEidtorMenuModel) {
//        let vc = ChangeBoardViewController()
//        vc.noteInfo = noteInfo
//        vc.callbackChooseBoard = { boardBlock in
//            model.moveBoard(boardBlock: boardBlock)
//        }
//        self.controller?.present(MyNavigationController(rootViewController: vc), animated: true, completion: nil)
//    }
//
//    private func openChooseBackgroundVC(noteInfo:NoteInfo,model:NoteEidtorMenuModel) {
//
//        let colorVC = NoteColorViewController()
//        colorVC.selectedColor = noteInfo.properties.backgroundColor
//        colorVC.callbackColorChoosed = { background in
//            model.update(background: background)
//        }
//
//        let nav = MyNavigationController(rootViewController: colorVC)
//        nav.modalPresentationStyle = .custom
//        nav.transitioningDelegate = colorVC.self
//        self.controller?.present(nav, animated: true, completion: nil)
//    }
}


////MARK: 添加 block
extension NotesView {
    func setupFloatButtons() {
        self.addSubview(toolbar)
        toolbar.snp.makeConstraints { (make) -> Void in
            make.width.equalToSuperview()
            make.height.equalTo(ToolbarConstants.height)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin)
        }
        
        
    }
    
    @objc func btnNewNoteTapped (sender:UIButton) {
        self.createTextNote()
    }
    
    
//    private func handleNoteInserted(_ noteInfo:NoteInfo) {
//        self.noteInfos.insert(noteInfo, at: 0)
//        self.collectionNode.performBatchUpdates({
//            self.collectionNode.insertItems(at: [IndexPath(row: 0, section: 0)])
//        }, completion: { _ in
//            self.openEditorVC(note: noteInfo,isNew: true)
//        })
//    }
    func openEditorVC(cardBlock: BlockInfo,isNew:Bool = false) {
        let noteVC  = CardEditorViewController()
//        noteVC.cardBlock = cardBlock
//        noteVC.callbackNoteUpdate = {event in
//            self.handleNoteInfoEvent(event: event)
//        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    //
    @objc func btnMoreTapped (sender:UIButton) {
        NotesView.showNotesMenu(sourceView: sender, sourceVC: self.controller!,isIncludeText: false) { [weak self]  menuType in
            self?.openNoteEditor(type:menuType)
        }
    }
    
    private func openNoteEditor(type: MenuType) {
        switch type {
        case .text:
            self.createTextNote()
        case .todo:
            self.createTodoNote()
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
        case .bookmark:
            self.controller?.showAlertTextField(title: "添加链接",placeholder: "example.com", positiveBtnText: "添加", callbackPositive: { _ in
                //                self.fetchBookmarkFromUrl(url: $0)
            })
            break
        }
    }
    
    
    static func showNotesMenu(sourceView: UIView,sourceVC:UIViewController,isIncludeText:Bool = true,callback: @escaping (MenuType)->Void) {
        var items = [
            ContextMenuItem(label: "待办事项", icon: "checkmark.square", tag: MenuType.todo),
            ContextMenuItem(label: "相册", icon: "photo.on.rectangle", tag: MenuType.image),
            ContextMenuItem(label: "拍照", icon: "camera", tag: MenuType.camera),
            ContextMenuItem(label: "链接", icon: "link", tag: MenuType.bookmark),
        ]
        if isIncludeText {
            items.insert(ContextMenuItem(label: "文本", icon: "textbox", tag: MenuType.text), at: 0)
        }
        
        ContextMenuViewController.show(sourceView:sourceView, sourceVC: sourceVC,menuWidth:180, items: items) {item, vc in
            if let menuType = item.tag as? MenuType {
                callback(menuType)
            }
        }
    }
    
    static func  makeFloatButton() -> UIButton {
        let btn = ActionButton()
        btn.contentMode = .center
//        btn.clipsToBounds = true
        btn.adjustsImageWhenHighlighted = false
        let layer0 = btn.layer
        
        layer0.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 4
        layer0.shadowOffset = CGSize(width: 2, height: 2)
        return btn
    }
    
}
extension UIColor {
//    func darker() -> UIColor {
//
//        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
//
//        let p:CGFloat = 0.3
//
//        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
//            return UIColor(red: max(r - p, 0.0), green: max(g - p, 0.0), blue: max(b - p, 0.0), alpha: a)
//        }
//
//        return UIColor()
//    }
//
//    func lighter() -> UIColor {
//
//        var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
//
//        if self.getRed(&r, green: &g, blue: &b, alpha: &a){
//            return UIColor(red: min(r + 0.2, 1.0), green: min(g + 0.2, 1.0), blue: min(b + 0.2, 1.0), alpha: a)
//        }
//
//        return UIColor()
//    }
}



//MARK: 创建 note
extension NotesView {
    
    
    private func createTextNote() {
//        var noteBlockInfo = generateNoteBlock()
//        let textBlockInfo = Block.text(parentId: noteBlockInfo.id, position: BlockConstants.position/3)
//        noteBlockInfo.contentBlocks.append(textBlockInfo)
//        self.createNote(noteBlockInfo: noteBlockInfo)
    }
    
    private func createTodoNote() {
//        var noteBlockInfo = generateNoteBlock()
//
//        var todoGroupBlock = Block.group(parent: noteBlockInfo.id, properties: BlockGroupProperty(tag: NoteInfoGroupTag.todo.rawValue), position: BlockConstants.position / 2)
//
//        let todoBlockInfo = Block.todo(parentId: todoGroupBlock.id, position: BlockConstants.position)
//        todoGroupBlock.contentBlocks.append(todoBlockInfo)
//
//        noteBlockInfo.contentBlocks.append(todoGroupBlock)
//        self.createNote(noteBlockInfo: noteBlockInfo)
    }
    
    private func createImagesNote(imageProperties:[BlockImageProperty]) {
//        var noteBlockInfo = generateNoteBlock()
//
//        var imageGroupBlock = Block.group(parent: noteBlockInfo.id, properties: BlockGroupProperty(tag: NoteInfoGroupTag.attachment.rawValue), position: BlockConstants.position)
//        let images:[BlockInfo] = imageProperties.enumerated().map {
//            let position = Double($0.offset+1) * BlockConstants.position
//            return Block.image(parent: imageGroupBlock.id, properties: $0.element, position: position)
//        }
//        imageGroupBlock.contentBlocks.append(contentsOf: images)
//
//        noteBlockInfo.contentBlocks.append(imageGroupBlock)
//
//
//        self.createNote(noteBlockInfo: noteBlockInfo)
        
    }
    
    private func generateNoteBlock() -> BlockInfo {
        let postion = self.cards.count == 0 ? 65536 : self.cards[0].position / 2
        let noteBlockInfo = Block.note(title: "", parentId: self.board.id, position: postion)
        return noteBlockInfo
    }
    
    
    private func createNote(noteBlockInfo:BlockInfo) {
//        NoteRepo.shared.createNote(noteInfo: noteBlockInfo)
//            .subscribe(onNext: {
//                self.handleNoteInserted($0)
//            }, onError: {
//                Logger.error($0)
//            })
//            .disposed(by: disposeBag)
    }
    
    
    
}
//
////MARK: 超链接处理
//extension NotesView {
//
//    private func fetchBookmarkFromUrl(url:String) {
//        let links = SwiftLinkPreview(session: .shared, workQueue: SwiftLinkPreview.defaultWorkQueue, responseQueue: DispatchQueue.main, disableInMemoryCache: true,cacheInvalidationTimeout: 0, cacheCleanupInterval: 0)
//        links.preview(url,
//                onSuccess: { result in
//                    let title = result.title ?? ""
//                    let description = result.description ?? ""
//                    let cover = result.image ?? ""
//                    let finalUrl = result.finalUrl?.absoluteURL.absoluteString ?? url
//                    let canonicalUrl = result.canonicalUrl ?? ""
//
//                    let properties = BlockBookmarkProperty(title:title,cover: cover, link:finalUrl,description: description, canonicalUrl: canonicalUrl)
//                    self.createBookmarkBlock(properties)
//                },
//                onError: { error in print("\(error)")})
//    }
//
//    private func createBookmarkBlock(_ properties:BlockBookmarkProperty) {
//
//        func handleBookmark(_ properties:BlockBookmarkProperty) {
//            let noteBlock = Block.newNoteBlock()
//            let bookmarkBlock = Block.newBookmarkBlock(parent: noteBlock.id, properties: properties)
//            self.createNewNote(noteBlock: noteBlock, childBlock: bookmarkBlock)
//        }
//
//        if properties.cover.isEmpty {
//            handleBookmark(properties)
//            return
//        }
//
//        var newImageInfo = properties
//        // 保存图片到本地
////        NoteRepo.shared.saveImage(url: newImageInfo.cover)
////            .subscribe {
////                newImageInfo.cover = $0
////                handleBookmark(newImageInfo)
////            } onError: {
////                Logger.error($0)
////            }
////            .disposed(by: disposeBag)
//    }
//
//}
//
//
extension NotesView: TLPhotosPickerViewControllerDelegate {
    func shouldDismissPhotoPicker(withTLPHAssets: [TLPHAsset]) -> Bool {
        self.handlePicker(images: withTLPHAssets)
        return true
    }
    
    func handlePicker(images: [TLPHAsset]) {
        self.controller?.showHud()
//        NoteRepo.shared.saveImages(images: images)
//            .subscribe {
//                self.createImagesNote(imageProperties: $0)
//            } onError: {
//                Logger.error($0)
//            } onCompleted: {
//                self.controller?.hideHUD()
//            }
//            .disposed(by: disposeBag)
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
//        NoteRepo.shared.saveImage(image: image)
//            .subscribe {
//                self.createImagesNote(imageProperties: [$0])
//            } onError: {
//                Logger.error($0)
//            } onCompleted: {
//                self.controller?.hideHUD()
//            }
//            .disposed(by: disposeBag)
    }
}

struct MenuItem  {
    var label: String
    var icon: String
    var type: MenuType
}

enum MenuType:Int {
    case text = 0
    case image = 1
    case camera = 2
    case todo = 3
    case bookmark = 4
}
