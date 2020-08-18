//
//  BoardView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/17.
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


enum BoardViewConstants {
    static let cellSpace: CGFloat = 12
    static let cellVerticalSpace: CGFloat = 14
    static let cellHorizontalSpace: CGFloat = 14
    
    static let cornerRadius:CGFloat = 8
    
    static let waterfall_cellSpace: CGFloat = 0
    static let waterfall_cellHorizontalSpace: CGFloat = 10
    
}


protocol BoardViewDelegate:AnyObject {
    func embeddedBlockTapped(block:Block)
}

class BoardView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    
    private var cards:[BlockInfo] = []
    var callbackSearchButtonTapped:((UIButton)->Void)!
    
    
    private var board:BlockInfo!
    private var noteStatus:NoteBlockStatus = NoteBlockStatus.normal
    
    private var numberOfColumns = 2
   
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns),
                                                      columnSpacing: BoardViewConstants.waterfall_cellSpace,
                                                      interItemSpacing: BoardViewConstants.waterfall_cellSpace,
                                                      sectionInsets: UIEdgeInsets(top: BoardViewConstants.waterfall_cellSpace, left: BoardViewConstants.waterfall_cellHorizontalSpace, bottom: BoardViewConstants.waterfall_cellSpace, right:  BoardViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
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
            $0.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 160, right: 0)
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
        if noteStatus == NoteBlockStatus.normal {
            self.setupFloatButtons()
        }
        
        let boardView = BoardActionView()
        boardView.noteButton.addTarget(self, action: #selector(handleNoteButtonTapped), for: .touchUpInside)
        self.addSubview(boardView)
        boardView.snp.makeConstraints {
            $0.height.equalTo(FloatButtonConstants.btnSize)
            
            let w = BoardActionViewConstants.noteBtnWidth + BoardActionViewConstants.moreBtnWidth + 0.5
            $0.width.equalTo(w)
            $0.trailing.equalToSuperview().offset(-FloatButtonConstants.trailing)
            $0.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin).offset(-FloatButtonConstants.bottom)
        }
    }
    
    @objc func handleNoteButtonTapped(button:UIButton) {
        self.createNewNote()
    }
    
    private func setupData() {
        BlockRepo.shared.getBlockInfos2(ownerId: board.id)
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    self.cards = $0
                    self.collectionNode.reloadData()
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
}

extension BoardView {
    private func createNewNote() {
        let position = self.cards.count > 0 ? self.cards[0].position / 2 : 65536
        self.createBlockInfo(blockInfo: Block.note(title: "", parentId: board.id, position:position ))
    }
    
    private func createBlockInfo(blockInfo:BlockInfo) {
       BlockRepo.shared.createBlock(blockInfo)
            .subscribe { [weak self] cardBlock in
                self?.handleCreateBlock(cardBlock)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposeBag)
    }
    
    private func handleCreateBlock(_ cardBlock:BlockInfo) {
       self.openEditorVC(cardBlock: cardBlock, isNew: true)
       self.insertBlockCell(block: cardBlock)
    }
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


extension BoardView: ASCollectionDataSource {
    
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
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let cardBlock = self.cards[indexPath.row]
        return {
            let node =  CardCellNode(cardBlock:cardBlock )
//            node.delegate = self
            return node
        }
    }
    
}

extension BoardView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let cardBlock = self.cards[indexPath.row]
        self.openEditorVC(cardBlock: cardBlock)
    }
    func openEditorVC(cardBlock: BlockInfo,isNew:Bool = false) {
        let viewModel:CardEditorViewModel = CardEditorViewModel(blockInfo: cardBlock)
        let noteVC  = CardEditorViewController()
        noteVC.viewModel = viewModel
        noteVC.isNew = isNew
        noteVC.updateCallback = { [weak self] event in
            self?.handleEditorUpdateEvent(event: event)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
    func handleEditorUpdateEvent(event:EditorUpdateEvent) {
        switch event {
            case .updated(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .statusChanged(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .backgroundChanged(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .moved(block: let block, boardBlock: let boardBlock):
                self.removeBlockCell(block: block)
                print(boardBlock.title)
                break
            case .delete(block: let block):
                self.removeBlockCell(block: block)
                break
        }
    }
    
    private func refreshBlockCell(block:BlockInfo) {
        guard let index = self.cards.firstIndex(where: {$0.id == block.id}) else { return }
        self.cards[index] = block
        self.collectionNode.performBatchUpdates({
            self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
        }, completion: nil)
    }
    
    private func removeBlockCell(block:BlockInfo) {
        
    }
    private func insertBlockCell(block:BlockInfo,at:Int = 0) {
        self.cards.insert(block, at: at)
        self.collectionNode.performBatchUpdates({
            self.collectionNode.insertItems(at: [IndexPath(row: at, section: 0)])
        }, completion: nil)
    }
}

//MARK: CONTEXT MENU
extension BoardView: UICollectionViewDelegate{
    
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
extension BoardView {
    func setupFloatButtons() {
//        self.addSubview(toolbar)
//        toolbar.snp.makeConstraints { (make) -> Void in
//            make.width.equalToSuperview()
//            make.height.equalTo(ToolbarConstants.height)
//            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin)
//        }
    }
    
    @objc func btnNewNoteTapped (sender:UIButton) {
//        self.createTextNote()
    }
    
    
//    private func handleNoteInserted(_ noteInfo:NoteInfo) {
//        self.noteInfos.insert(noteInfo, at: 0)
//        self.collectionNode.performBatchUpdates({
//            self.collectionNode.insertItems(at: [IndexPath(row: 0, section: 0)])
//        }, completion: { _ in
//            self.openEditorVC(note: noteInfo,isNew: true)
//        })
//    }
//    func openEditorVC(note: NoteInfo,isNew:Bool = false) {
//        let noteVC  = EditorViewController()
//        noteVC.note = note
//        noteVC.isNew = isNew
//        noteVC.callbackNoteUpdate = {event in
//            self.handleNoteInfoEvent(event: event)
//        }
//        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
//    }
    //
    @objc func btnMoreTapped (sender:UIButton) {
        NotesView.showNotesMenu(sourceView: sender, sourceVC: self.controller!,isIncludeText: false) { [weak self]  menuType in
            self?.openNoteEditor(type:menuType)
        }
    }
    
    private func openNoteEditor(type: MenuType) {
        switch type {
        case .text:
//            self.createTextNote()
            break
        case .todo:
//            self.createTodoNote()
            break
        case .image:
            let viewController = TLPhotosPickerViewController()
//            viewController.delegate = self
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
//            vc.delegate = self
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
        let btn = UIButton()
        btn.contentMode = .center
        let layer0 = btn.layer
        layer0.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 4
        layer0.shadowOffset = CGSize(width: 0, height: 2)
        layer0.cornerRadius = FloatButtonConstants.btnSize / 2
        layer0.backgroundColor = UIColor(red: 0.278, green: 0.627, blue: 0.957, alpha: 1).cgColor
        return btn
    }
    
}

//MARK: 创建 note
extension BoardView {
    
    
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
extension BoardView: TLPhotosPickerViewControllerDelegate {
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

extension BoardView: UIImagePickerControllerDelegate {
    
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
