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
    static let cellHorizontalSpace: CGFloat = 14
    
    static let waterfall_cellSpace: CGFloat = 12
    static let waterfall_cellHorizontalSpace: CGFloat = 14
    
}

enum FloatButtonConstants {
    static let btnSize:CGFloat = 54
    static let trailing:CGFloat = 14
    static let bottom:CGFloat = 20
    static let iconSize:CGFloat = 20
}


protocol NotesViewDelegate:AnyObject {
    func embeddedBlockTapped(block:Block)
}

class NotesView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
//
//    private var selectedIndexPath:IndexPath?
//    private var sectionNoteInfo:SectionNoteInfo! {
//        didSet {
//            if oldValue != nil &&  oldValue.notes.count != sectionNoteInfo.notes.count {
//                self.callbackNotesCountChanged?(Int64(sectionNoteInfo.notes.count))
//            }
//        }
//    }
//
    private var noteInfos:[NoteInfo] = []
    
    
    static func getItemSize(numberOfColumns:Int) -> CGSize {
        let validWidth = UIScreen.main.bounds.width - NotesViewConstants.cellHorizontalSpace * CGFloat(numberOfColumns) - NotesViewConstants.cellSpace*CGFloat(numberOfColumns-1)
        let itemWidth = validWidth / CGFloat(numberOfColumns)
        let itemHeight = itemWidth * 200 / 160
        return CGSize(width: itemWidth, height: itemHeight)
    }
//
//    var delegate:NotesViewDelegate?
//    var callbackNotesCountChanged:((Int64)->Void)?
//
    private var board:BlockInfo!
    private var noteStatus:NoteBlockStatus = NoteBlockStatus.normal
//
    private var numberOfColumns = 2
    private lazy var itemContentSize =  NotesView.getItemSize(numberOfColumns: self.numberOfColumns)
//
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns), columnSpacing:  NotesViewConstants.waterfall_cellSpace, interItemSpacing: NotesViewConstants.waterfall_cellSpace, sectionInsets: UIEdgeInsets(top: 12, left: NotesViewConstants.waterfall_cellHorizontalSpace, bottom: 12, right:  NotesViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
    }
//
//
    private lazy var collectionLayout =  UICollectionViewFlowLayout().then {
//        var itemSize = itemContentSize
//        itemSize.height = itemContentSize.height + NoteCellConstants.boardHeight
        $0.itemSize = itemContentSize
        $0.minimumInteritemSpacing = NotesViewConstants.cellSpace
        $0.minimumLineSpacing = NotesViewConstants.cellSpace
    }
//
    private var mode:DisplayMode = .grid
    private(set) lazy var collectionNode = self.generateCollectionView(mode: mode)
//
//
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
        collectionNode.backgroundColor = .clear
        self.addSubnode(collectionNode)
        if noteStatus == NoteBlockStatus.normal {
            self.setupFloatButtons()
        }
    }

    private func setupData() {
        NoteRepo.shared.queryNotes(boardId: self.board.id)
                .subscribe(onNext: { [weak self] in
                    if let self = self {
                        self.noteInfos = $0
                        self.collectionNode.reloadData()
                    }
                }, onError: {
                    Logger.error($0)
                })
            .disposed(by: disposeBag)

    }
    
}

extension NotesView {
    
//    func viewWillAppear(_ animated: Bool) {
//
//    }
//
//
//    func viewWillDisappear(_ animated: Bool) {
//        //        notesToken?.invalidate()
//    }
//
    func noteEditorUpdated(mode:EditorUpdateMode) {
        switch mode {
        case .updated(noteInfo: let noteInfo):
            if let row = noteInfos.firstIndex(where: { $0.id == noteInfo.id }) {
                self.noteInfos[row] = noteInfo
                self.collectionNode.performBatchUpdates({
                    self.collectionNode.reloadItems(at: [IndexPath(row: row, section: 0)])
                }, completion: nil)
            }
            break
        case .deleted(noteInfo: let noteInfo):
            self.handleDeleteNote(noteInfo)
            break
        case .moved(noteInfo: let noteInfo):
            self.handleDeleteNote(noteInfo)
            break
        case .archived(noteInfo: let noteInfo):
            self.handleDeleteNote(noteInfo)
            break
        case .trashed(noteInfo: let noteInfo):
            self.handleDeleteNote(noteInfo)
            break
        }
    }
    func handleDeleteNote(_ note:NoteInfo) {
        if let row = noteInfos.firstIndex(where: { $0.id == note.id }) {
            noteInfos.remove(at: row)
            self.collectionNode.performBatchUpdates({
                self.collectionNode.deleteItems(at: [IndexPath(row: row, section: 0)])
            }, completion:nil)
        }
    }
}

extension NotesView {
    
    private func createNewNote(noteBlock:Block,childBlock:Block,callback:((Note) -> Void)? = nil) {
//        self.createNewNote(noteBlock:noteBlock,childBlocks:[childBlock],callback:callback)
    }
    private func createNewNote(noteBlock:Block,childBlocks:[Block],callback:((Note) -> Void)? = nil) {
//        NoteRepo.shared.createNewNote(sectionId: self.sectionNoteInfo.section.id,noteBlock:noteBlock, childBlocks: childBlocks)
//            .subscribe { [weak self] note in
//                if let callback = callback {
//                    callback(note)
//                    return
//                }
//                self?.openEditorVC(note:note, isNew: true)
//            } onError: {
//                Logger.error($0)
//            }
//            .disposed(by: disposeBag)
    }
    
}


extension NotesView: ASCollectionDataSource {

    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }

    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        let count = self.noteInfos.count
        if count == 0 {
            collectionNode.setEmptyMessage("暂无便签")
        }else {
            collectionNode.clearEmptyMessage()
        }
        return count
    }

    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let note = self.noteInfos[indexPath.row]
        return {
            let node =  NoteCellNode(note: note,itemSize: self.itemContentSize)
            node.delegate = self
            return node
        }
    }

}

extension NotesView:NoteCellNodeDelegate {
    func noteCellImageBlockTapped(imageView: ASImageNode, note: Note) {

        let defaultImage: UIImage = imageView.image!
        let browser = PhotoViewerViewController(note: note)
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            imageView.image = defaultImage
            return imageView.view
        })
        browser.callBackShowNoteButtonTapped = {
            if let noteIndex = self.noteInfos.firstIndex(where: {$0.id == note.id}) {
                self.openEditorVC(note: self.noteInfos[noteIndex])
            }
        }
        browser.show()
    }

    func noteCellImageBlockTapped(imageView: ASImageNode, blocks: [Block], index: Int) {

    }


    func noteCellBlockTapped(block: Block) {

    }

    func noteCellMenuTapped(sender: UIView,note:Note) {
        NoteMenuViewController.show(mode: .list, note: note,sourceView: sender,delegate: self)
    }
}
//
////MARK: NoteMenuViewControllerDelegate
extension NotesView:NoteMenuViewControllerDelegate {
    func noteMenuArchive(note: Note) {
//        self.handleDeleteNote(note)
    }

    func noteMenuMoveToTrash(note: Note) {
//        self.handleDeleteNote(note)
//        self.showToast("便签已移动至废纸篓")
    }

    func noteMenuChooseBoards(note: Note) {

    }

    func noteMenuBackgroundChanged(note: Note) {
//        guard let row = self.noteInfos.firstIndex(where: {$0.id == note.id}) else { return }
//        self.sectionNoteInfo.notes[row] = note
//        if let noteCell = collectionNode.nodeForItem(at: IndexPath(row: row, section: 0)) as? NoteCellNode {
//            noteCell.note = note
//            noteCell.setupBackBackground()
//        }
    }

    func noteMenuDataMoved(note: Note) {
//        self.handleDeleteNote(note)

//        guard let board = note.board else { return }
//
//        let message = board.type == BoardType.user.rawValue ? (board.icon+board.title) : board.title
//        self.showToast("便签已移动至：\"\(message)\"")
    }

}

extension NotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let note = self.noteInfos[indexPath.row]
        self.openEditorVC(note: note)
    }
}

////MARK: 添加 block
extension NotesView {
    func setupFloatButtons() {
        let btnNewNote = NotesView.makeFloatButton().then {
            $0.backgroundColor = .brand
            $0.tintColor = .white
            $0.setImage( UIImage(systemName: "square.and.pencil", pointSize: FloatButtonConstants.iconSize, weight: .light), for: .normal)
            $0.addTarget(self, action: #selector(btnNewNoteTapped), for: .touchUpInside)
        }
        self.addSubview(btnNewNote)
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(FloatButtonConstants.btnSize)
            make.trailing.equalTo(self).offset(-FloatButtonConstants.trailing)
            make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin).offset(-FloatButtonConstants.bottom)
        }


        let btnMore =  NotesView.makeFloatButton().then {
            $0.tintColor = .brand
            $0.backgroundColor = .white
            $0.setImage(UIImage(systemName: "ellipsis", pointSize: FloatButtonConstants.iconSize, weight: .light)?.withTintColor(.white), for: .normal)
            $0.addTarget(self, action: #selector(btnMoreTapped), for: .touchUpInside)
        }
        self.addSubview(btnMore)
        btnMore.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(FloatButtonConstants.btnSize)
            make.bottom.equalTo(btnNewNote.snp.top).offset(-16)
            make.trailing.equalTo(btnNewNote.snp.trailing)
        }
    }

    @objc func btnNewNoteTapped (sender:UIButton) {
        
    }
    
    
    private func handleNoteInserted(_ noteInfo:NoteInfo) {
       self.noteInfos.insert(noteInfo, at: 0)
        self.collectionNode.performBatchUpdates({
            self.collectionNode.insertItems(at: [IndexPath(row: 0, section: 0)])
        }, completion: { _ in
            self.openEditorVC(note: noteInfo)
        })
    }
    func openEditorVC(note: NoteInfo,isNew:Bool = false) {
        let noteVC  = EditorViewController()
        noteVC.note = note
        noteVC.isNew = isNew
//        noteVC.mode = isNew ? EditorMode.create(noteInfo: note) :  EditorMode.browser(noteInfo: note)
        noteVC.callbackNoteUpdate = {updateMode in
            self.noteEditorUpdated(mode: updateMode)
        }
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
extension NotesView {
    
    
    private func createTextNote() {
        var noteBlockInfo = generateNoteBlock()
        let textBlockInfo = Block.text(parentId: noteBlockInfo.id, position: 65536)
        noteBlockInfo.contentBlocks.append(textBlockInfo)
        self.createNote(noteBlockInfo: noteBlockInfo)
    }
    
    private func createTodoNote() {
        var noteBlockInfo = generateNoteBlock()
        let textBlockInfo = Block.text(parentId: noteBlockInfo.id, position: 65536)
        noteBlockInfo.contentBlocks.append(textBlockInfo)
        self.createNote(noteBlockInfo: noteBlockInfo)
    }
    
    private func createImagesNote(imageProperties:[BlockImageProperty]) {
        var noteBlockInfo = generateNoteBlock()
        
        var imageGroupBlock = Block.group(parent: noteBlockInfo.id, properties: BlockGroupProperty(tag: NoteInfoGroupTag.attachment.rawValue), position: BlockConstants.position)
        let images:[BlockInfo] = imageProperties.enumerated().map {
            let position = Double($0.offset+1) * BlockConstants.position
            return Block.image(parent: imageGroupBlock.id, properties: $0.element, position: position)
        }
        imageGroupBlock.contentBlocks.append(contentsOf: images)
        
        noteBlockInfo.contentBlocks.append(imageGroupBlock)
        
        
        self.createNote(noteBlockInfo: noteBlockInfo)
        
    }
    
    private func generateNoteBlock() -> BlockInfo {
        let postion = self.noteInfos.count == 0 ? 65536 : self.noteInfos[0].position / 2
        let noteBlockInfo = Block.note(title: "", parentId: self.board.id, position: postion)
        return noteBlockInfo
    }
    
    
    private func createNote(noteBlockInfo:BlockInfo) {
        NoteRepo.shared.createNote(noteInfo: noteBlockInfo)
            .subscribe(onNext: {
                self.handleNoteInserted($0)
            }, onError: {
                Logger.error($0)
            })
        .disposed(by: disposeBag)
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
        NoteRepo.shared.saveImages(images: images)
            .subscribe {
                self.createImagesNote(imageProperties: $0)
            } onError: {
                Logger.error($0)
            } onCompleted: {
                self.controller?.hideHUD()
            }
            .disposed(by: disposeBag)
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
        NoteRepo.shared.saveImage(image: image)
            .subscribe {
                self.createImagesNote(imageProperties: [$0])
            } onError: {
                Logger.error($0)
            } onCompleted: {
                self.controller?.hideHUD()
            }
            .disposed(by: disposeBag)
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
    case bookmark
}
