//
//  TrashView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/11.
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


class TrashView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    private var cards:[BlockInfo] = [] {
        didSet {
//            self.controller?.navigationController?.isToolbarHidden = cards.isEmpty
        }
    }
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
    private var boardsMap:[String:BlockInfo] = [:]
    
    convenience init(frame: CGRect,boardsMap:[String:BlockInfo]) {
        self.init(frame:frame)
        self.boardsMap = boardsMap
        self.setupUI()
        self.setupData()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        collectionNode.frame = self.frame
        collectionNode.backgroundColor = .bg
        self.addSubnode(collectionNode)
    }
    
    
    private func setupData() {
        BlockRepo.shared.getCards(status:.trash)
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

    func handleClearTrash() {
        if self.cards.isEmpty {return}
        let alert = UIAlertController(title: "", message: "清空后的内容将不能够被恢复。确认要清空吗？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "确认清空", style: .destructive , handler:{ (UIAlertAction)in
            self.clearTrash()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        self.controller?.present(alert, animated: true, completion:nil)
    }
    func handleRestoreTrash() {
        if self.cards.isEmpty {return}
        self.restoreTrash()
    }
    
    private func clearTrash() {
        BlockRepo.shared.deleteTrashCards()
            .subscribe {
                self.cards.removeAll()
                self.collectionNode.reloadData()
            } onError: {
                Logger.error($0)
            }.disposed(by: disposeBag)
    }
    
    private func restoreTrash() {
        BlockRepo.shared.restoreTrashCards()
            .subscribe {
                self.cards.removeAll()
                self.collectionNode.reloadData()
            } onError: {
                Logger.error($0)
            }.disposed(by: disposeBag)
    }
}


extension TrashView: ASCollectionDataSource {
    
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

extension TrashView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let cardBlock = self.cards[indexPath.row]
        self.openEditorVC(card: cardBlock)
    }
    func openEditorVC(card: BlockInfo,isNew:Bool = false) {
        
        guard let board = self.boardsMap[card.ownerId] else { return }
        let viewModel:CardEditorViewModel = CardEditorViewModel(blockInfo: card,board: board)
        let noteVC  = CardEditorViewController()
        noteVC.viewModel = viewModel
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
                if block.block.status != .trash {
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

    
   
//    private var numberOfColumns = 2
//    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
//        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns), columnSpacing:  NotesViewConstants.waterfall_cellSpace, interItemSpacing: NotesViewConstants.waterfall_cellSpace, sectionInsets: UIEdgeInsets(top: 0, left: NotesViewConstants.waterfall_cellHorizontalSpace, bottom: 12, right:  NotesViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
//    }
//    
//    private lazy var collectionLayout =  UICollectionViewFlowLayout().then {
//        $0.itemSize = CGSize(width: itemContentSize.width, height: itemContentSize.height + NoteCellConstants.boardHeight )
//        $0.minimumInteritemSpacing = NotesViewConstants.cellSpace
//        $0.minimumLineSpacing = NotesViewConstants.cellVerticalSpace
//    }
//    
//    private var mode:DisplayMode = .grid
//    private(set) lazy var collectionNode = self.generateCollectionView(mode: mode)
//    
//    
//    func generateCollectionView(mode:DisplayMode) -> ASCollectionNode {
//        switch mode {
//        case .waterfall:
//            return ASCollectionNode(layoutDelegate: layoutDelegate, layoutFacilitator: nil).then { [weak self] in
//                guard let self = self else {return}
//                $0.alwaysBounceVertical = true
//                let _layoutInspector = layoutDelegate
//                $0.dataSource = self
//                $0.delegate = self
//                $0.layoutInspector = _layoutInspector
//                $0.contentInset = UIEdgeInsets(top: 0, left: NotesViewConstants.cellHorizontalSpace, bottom: 160, right: NotesViewConstants.cellHorizontalSpace)
//                $0.showsVerticalScrollIndicator = false
//                $0.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
//                
//            }
//        case .grid:
//            return ASCollectionNode(collectionViewLayout:collectionLayout).then { [weak self] in
//                guard let self = self else {return}
//                $0.alwaysBounceVertical = true
//                $0.dataSource = self
//                $0.delegate = self
//                $0.contentInset = UIEdgeInsets(top: 12, left: NotesViewConstants.cellHorizontalSpace, bottom: 160, right: NotesViewConstants.cellHorizontalSpace)
//                $0.showsVerticalScrollIndicator = false
//                
//                $0.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
//                
//            }
//        }
//    }
//    
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        self.setupUI()
//        self.setupData()
//    }
//    
//    
//    private func setupUI() {
//        collectionNode.frame = self.frame
//        collectionNode.backgroundColor = .clear
//        self.addSubnode(collectionNode)
//        self.setupFloatButtons()
//    }
//    
   
//    
//}
//
//
//extension TrashView: ASCollectionDataSource {
//    
//    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
//        return 1
//    }
//    
//    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
//        let count = self.notes.count
//        if count == 0 {
//            collectionNode.setEmptyMessage("暂无便签")
//        }else {
//            collectionNode.clearEmptyMessage()
//        }
//        return count
//    }
//    
//    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
//        let note = self.notes[indexPath.row]
//        let boardBlock = self.boardsMap[note.noteBlock.blockPosition.ownerId]!
//        let itemSize = self.itemContentSize
//        return {
//            let node =  NoteCellNode(note: note,itemSize: itemSize,board: boardBlock)
//            node.delegate = self
//            node.callbackBoardButtonTapped = { [weak self] _,boardBlock in
//                self?.callbackOpenBoard?(boardBlock)
//            }
//            return node
//        }
//    }
//    
//}
//
//
//extension TrashView: ASCollectionDelegateFlowLayout {
//    func collectionNode(_ collectionNode: ASCollectionNode, sizeRangeForHeaderInSection section: Int) -> ASSizeRange {
//        return ASSizeRangeUnconstrained
//    }
//}
//
//
//extension TrashView:NoteCellNodeDelegate {
//    func noteCellImageBlockTapped(imageView: ASImageNode, note: Note) {
//        let defaultImage: UIImage = imageView.image!
////        let browser = PhotoViewerViewController(note: note)
////        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
////            imageView.image = defaultImage
////            return imageView.view
////        })
////        browser.callBackShowNoteButtonTapped = {
////            //            if let indexPath = self.findNoteIndex(note)
////            //            self.openEditorVC(note: self.noteInfos[])
////            self.openEditorVC(note: note)
////        }
////        browser.show()
//    }
//    
//    
//    func noteCellBlockTapped(block: Block) {
//        
//    }
//    
//    func noteCellMenuTapped(sender: UIView,note:Note) {
////        NoteMenuViewController.show(mode:.trash,note: note, sourceView: sender, delegate: self)
//    }
//    
//    
//}
//
//
//
//
//
//extension TrashView: ASCollectionDelegate {
//    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
//        let note = self.notes[indexPath.row]
//        self.openEditorVC(note: note)
//    }
//    
//    
//    func openEditorVC(note: NoteInfo) {
//        let noteVC  = EditorViewController()
//        noteVC.note = note
//        noteVC.callbackNoteUpdate = {event in
//            self.handleNoteInfoEvent(event: event)
//        }
//        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
//    }
//}
//
//
////MARK: CONTEXT MENU
//extension TrashView: UICollectionViewDelegate{
//    
//    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
//            return self.makeContextMenu(noteInfo: self.notes[indexPath.row] )
//        })
//    }
//    
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
//        if let row = notes.firstIndex(where: { $0.id == noteInfo.id }) {
//            self.notes[row] = noteInfo
//            self.collectionNode.performBatchUpdates({
//                self.collectionNode.reloadItems(at: [IndexPath(row: row, section: 0)])
//            }, completion: nil)
//        }
//    }
//    
//    func handleDeleteNote(_ note:NoteInfo) {
//        if let row = notes.firstIndex(where: { $0.id == note.id }) {
//            notes.remove(at: row)
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
//        let colorVC = NoteColorViewController()
//        colorVC.selectedColor = noteInfo.properties.backgroundColor
//        colorVC.callbackColorChoosed = { background in
//            model.update(background: background)
//        }
//        let nav = MyNavigationController(rootViewController: colorVC)
//        nav.modalPresentationStyle = .custom
//        nav.transitioningDelegate = colorVC.self
//        self.controller?.present(nav, animated: true, completion: nil)
//    }
//}
