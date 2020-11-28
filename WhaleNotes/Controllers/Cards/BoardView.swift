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
    
    
    
    static let cellShadowSize:CGFloat = 8
    
    static let cornerRadius:CGFloat = 8
    
    static let waterfall_cellSpace: CGFloat = 0
    static let waterfall_cellHorizontalSpace: CGFloat = 8
    static let waterfall_verticalSpace: CGFloat = 8
    
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
                                                      columnSpacing: 0,
                                                      interItemSpacing: 0,
                                                      sectionInsets: UIEdgeInsets(top: 0, left: BoardViewConstants.waterfall_cellHorizontalSpace, bottom: BoardViewConstants.waterfall_verticalSpace, right:  BoardViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
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
            $0.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: HomeViewController.toolbarHeight+20, right: 0)
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
        
//        let boardView = BoardActionView()
//        boardView.noteButton.addTarget(self, action: #selector(handleNoteButtonTapped), for: .touchUpInside)
//        boardView.moreButton.addTarget(self, action: #selector(handleMoreButtonTapped), for: .touchUpInside)
//        self.addSubview(boardView)
//        boardView.snp.makeConstraints {
//            $0.height.equalTo(FloatButtonConstants.btnSize)
//            
//            let w = BoardActionViewConstants.noteBtnWidth + BoardActionViewConstants.moreBtnWidth + 0.5
//            $0.width.equalTo(w)
//            $0.trailing.equalToSuperview().offset(-FloatButtonConstants.trailing)
//            $0.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin).offset(-FloatButtonConstants.bottom)
//        }
    }
    
    @objc func handleNoteButtonTapped(button:UIButton) {
        self.createNewNote()
    }
    
    @objc func handleMoreButtonTapped (sender:UIButton) {
        NotesView.showNotesMenu(sourceView: sender, sourceVC: self.controller!,isIncludeText: false) { [weak self]  menuType in
            self?.openNoteEditor(type:menuType)
        }
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
    func createNewNote() {
        self.createBlockInfo(blockInfo: Block.note(title: "", parentId: board.id, position:generatePosition() ))
    }
    
    private func createTodoListBlock() {
        var todoListBlock = Block.todoList(parentId: board.id, position: generatePosition())
        let todoBlock = Block.todo(parentId: todoListBlock.id, position: 65536)
        todoListBlock.contents = [todoBlock]
        self.createBlockInfo(blockInfo: todoListBlock)
    }
    
    private func generatePosition() -> Double {
        let position = self.cards.count > 0 ? self.cards[0].position / 2 : 65536
        return position
    }
    
    private func createBlockInfo(blockInfo:BlockInfo) {
        BlockRepo.shared.executeActions(actions: [BlockInfoAction.insert(blockInfo: blockInfo)])
            .subscribe {
                self.handleCreateBlock(blockInfo)
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
        let viewModel:CardEditorViewModel = CardEditorViewModel(blockInfo: cardBlock,board: self.board)
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
                if block.block.status == .trash {
                  self.removeCardCell(card: block)
                  return
                }
                self.refreshBlockCell(block: block)
                break
            case .backgroundChanged(block: let block):
                self.refreshBlockCell(block: block)
                break
            case .moved(block: let block, boardBlock: let boardBlock):
                self.removeCardCell(card: block)
                print(boardBlock.title)
                break
            case .delete(block: let block):
                self.removeCardCell(card: block)
                break
        }
    }
    
    private func refreshBlockCell(block:BlockInfo) {
        guard let index = self.cards.firstIndex(where: {$0.id == block.id}) else { return }
        self.cards[index] = block
        UIView.performWithoutAnimation {
            self.collectionNode.performBatchUpdates({
                self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
            }, completion: nil)
        }
    }
    
    private func removeCardCell(card:BlockInfo) {
       guard let index = self.cards.firstIndex(where: {$0.id == card.id}) else { return }
        self.cards.remove(at: index)
        UIView.performWithoutAnimation {
            self.collectionNode.performBatchUpdates({
                self.collectionNode.deleteItems(at: [IndexPath(row: index, section: 0)])
            }, completion: nil)
        }
    }
    private func insertBlockCell(block:BlockInfo,at:Int = 0) {
        self.cards.insert(block, at: at)
        UIView.performWithoutAnimation {
            self.collectionNode.performBatchUpdates({
                self.collectionNode.insertItems(at: [IndexPath(row: at, section: 0)])
            }, completion: nil)
        }
    }
}


////MARK: 添加 block
extension BoardView {
    
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
    
    func openNoteEditor(type: MenuType) {
        switch type {
        case .text:
            self.createNewNote()
            break
        case .todo:
            self.createTodoListBlock()
            break
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
        
        BlockRepo.shared.createImageBlocks(images: images, ownerId: board.id)
            .subscribe {
                self.handleBlocksInserted($0)
            } onError: {
                Logger.error($0)
            } onCompleted: {
                self.controller?.hideHUD()
            }
            .disposed(by: disposeBag)
    }
    
    private func handleBlocksInserted(_ blocks:[BlockInfo]) {
        var indexPaths:[IndexPath] = []
        for i in 0..<blocks.count {
            indexPaths.append(IndexPath(row: i, section: 0))
        }
        self.cards.insert(contentsOf: blocks, at: 0)
        UIView.performWithoutAnimation {
            self.collectionNode.performBatchUpdates({
                self.collectionNode.insertItems(at: indexPaths)
            }, completion: nil)
        }
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
        BlockRepo.shared.createImageBlock(image: image, ownerId: self.board.id)
            .subscribe {
                self.handleBlocksInserted($0)
            } onError: {
                Logger.error($0)
            } onCompleted: {
                self.controller?.hideHUD()
            }
            .disposed(by: disposeBag)
    }
}
