//
//  SearchNotesView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/26.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
import SnapKit
import AsyncDisplayKit
import TLPhotoPicker
import RxSwift
import Photos
import ContextMenu
import JXPhotoBrowser

class SearchNotesView: UIView, UINavigationControllerDelegate {
    
    private lazy var disposeBag = DisposeBag()
    private var selectedIndexPath:IndexPath?
    
    var callbackCellBoardButtonTapped:((NoteInfo,BlockInfo)->Void)?
    var callbackNoteEdited:((_ editorUpdateMode:EditorUpdateMode) -> Void )!
    
    
    private var boardsMap:[String:BlockInfo] = [:]
    private var notes:[NoteInfo] = []
    
    var delegate:NotesViewDelegate?
    
    private var numberOfColumns = 2
    private lazy var itemContentSize =  NotesView.getItemSize(numberOfColumns: self.numberOfColumns)
    
    private lazy var collectionLayout =  UICollectionViewFlowLayout().then {
        var itemSize = itemContentSize
        itemSize.height = itemContentSize.height + NoteCellConstants.boardHeight
        $0.itemSize = itemSize
        $0.minimumInteritemSpacing = NotesViewConstants.cellSpace
        $0.minimumLineSpacing = NotesViewConstants.cellSpace
    }
    
    private var mode:DisplayMode = .grid
    private(set) lazy var collectionNode = self.generateCollectionView(mode: mode)
    private var keyword:String = ""
    
    func generateCollectionView(mode:DisplayMode) -> ASCollectionNode {
       return ASCollectionNode(collectionViewLayout:collectionLayout).then { [weak self] in
             guard let self = self else {return}
             $0.alwaysBounceVertical = true
             $0.dataSource = self
             $0.delegate = self
             $0.view.keyboardDismissMode = .onDrag
        $0.contentInset = UIEdgeInsets(top: 12, left: NotesViewConstants.cellHorizontalSpace, bottom: NotesViewConstants.cellSpace, right: NotesViewConstants.cellHorizontalSpace)
             $0.showsVerticalScrollIndicator = false
        }
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
    }
    
    func searchNotes(keyword:String) {
        self.keyword = keyword
        if keyword.isEmpty {
            self.notes = []
            self.collectionNode.reloadData()
            return
        }
        NoteRepo.shared.searchNotes(keyword: keyword)
            .subscribe {
                self.boardsMap = $0
                self.notes = $1
                self.collectionNode.reloadData()
            } onError: {
                Logger.error($0)
            }.disposed(by: disposeBag)
    }
}

extension SearchNotesView {
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
        self.callbackNoteEdited(mode)
        switch mode {
        case .updated(noteInfo: let noteInfo):
            self.handleNoteUpdated(noteInfo)
        case .deleted(noteInfo: let noteInfo):
            self.handleNoteDeleted(noteInfo)
        case .moved(let noteInfo,let boardBlock):
            self.handleNoteMoved(noteInfo,boardBlock)
        case .archived(noteInfo: let noteInfo):
            self.handleNoteUpdated(noteInfo)
        case .trashed(noteInfo: let noteInfo):
            self.handleNoteUpdated(noteInfo)
        }
    }
    
    func handleNoteUpdated(_ note:NoteInfo) {
        guard let index =  self.notes.firstIndex(where: { $0.id == note.id }) else { return }
        self.notes[index] = note
        self.collectionNode.performBatchUpdates({
            self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
        }, completion: nil)
    }
    
    func handleNoteMoved(_ note:NoteInfo,_ boardBlock:BlockInfo) {
        guard let index =  self.notes.firstIndex(where: { $0.id == note.id }) else { return }
        self.notes[index] = note
        self.boardsMap[note.noteBlock.parentId] = boardBlock
        self.collectionNode.performBatchUpdates({
            self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
        }, completion: nil)
    }
    
    func handleNoteDeleted(_ note:NoteInfo) {
        guard let index =  self.notes.firstIndex(where: { $0.id == note.id }) else { return }
        self.notes.remove(at: index)
        self.collectionNode.performBatchUpdates({
            self.collectionNode.deleteItems(at: [IndexPath(row: index, section: 0)])
        }, completion: nil)
    }
}


extension SearchNotesView: ASCollectionDataSource {

    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }

    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        let count = self.notes.count
        if count == 0 && self.keyword.isNotEmpty {
            collectionNode.setEmptyMessage("没有找到相关的便签",y: 150)
        }else {
            collectionNode.clearEmptyMessage()
        }
        return count
    }

    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let note = self.notes[indexPath.row]
        let itemSize = self.itemContentSize
        return {
            let board = self.boardsMap[note.noteBlock.parentId]
            let node =  NoteCellNode(note: note,itemSize: itemSize,board: board)
            node.delegate = self
            node.callbackBoardButtonTapped = { note,board in
                self.callbackCellBoardButtonTapped?(note,board)
            }
            return node
        }
    }

}

extension SearchNotesView:NoteCellNodeDelegate {
    func noteCellImageBlockTapped(imageView: ASImageNode, note: Note) {
        let defaultImage: UIImage = imageView.image!
        let browser = PhotoViewerViewController(note: note)
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            imageView.image = defaultImage
            return imageView.view
        })
        browser.callBackShowNoteButtonTapped = {
//            if let noteIndex = self.noteInfos.firstIndex(where: {$0.id == note.id}) {
//                self.openEditorVC(note: self.noteInfos[noteIndex])
//            }
        }
        browser.show()
    }
    
    func noteCellImageBlockTapped(imageView: ASImageNode, blocks: [Block], index: Int) {
        
    }
    
    func noteCellBlockTapped(block: Block) {
        
    }
    
    func noteCellMenuTapped(sender: UIView,note:Note) {
//        let menuStyle = note.status == NoteBlockStatus.trash ? NoteMenuDisplayMode.trash : NoteMenuDisplayMode.list
//        NoteMenuViewController.show(mode: menuStyle, note: note,sourceView: sender,delegate: self)
    }
}


extension SearchNotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let note = self.notes[indexPath.row]
        self.openEditorVC(note: note)
    }
}

// float buttons
extension SearchNotesView {
    
    func openEditorVC(note: NoteInfo,isNew:Bool = false) {
        let noteVC  = EditorViewController()
        noteVC.note = note
        noteVC.callbackNoteUpdate = {updateMode in
            self.noteEditorUpdated(mode: updateMode)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
}
