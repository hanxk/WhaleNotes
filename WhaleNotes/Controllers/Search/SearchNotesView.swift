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
    
//    private let editorUseCase = NoteRepo.shared
    
    private var selectedIndexPath:IndexPath?
    
    var callbackCellBoardButtonTapped:((Note,Board)->Void)?
    
    private var notes:[NoteAndBoard] = []
    
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
//             $0.dataSource = self
             $0.delegate = self
             $0.view.keyboardDismissMode = .onDrag
        $0.contentInset = UIEdgeInsets(top: 8, left: NotesViewConstants.cellHorizontalSpace, bottom: NotesViewConstants.cellSpace, right: NotesViewConstants.cellHorizontalSpace)
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
        
//        NoteRepo.shared.searchNotes(keyword: keyword)
//            .subscribe(onNext: { [weak self] in
//                if let self = self {
//                    self.notes = $0
//                    self.collectionNode.reloadData()
//                }
//            }, onError: {
//                Logger.error($0)
//            })
//        .disposed(by: disposeBag)
    }
}

extension SearchNotesView {
    
    func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    func viewWillDisappear(_ animated: Bool) {
    }
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
//        switch mode {
//        case .insert:
//            break
//        case .update(let note):
//            self.handleNoteUpdated(note)
//            break
//        case .delete(let note):
//            self.handleNoteDeleted(note)
//        case .moved(let note):
//            self.handleNoteUpdated(note)
//        case .trashed(let note):
//            self.handleNoteUpdated(note)
//        case .archived(let note):
//              self.handleNoteUpdated(note)
//        case .trashedOut(let note):
//            self.handleNoteUpdated(note)
//        }
    }
    
    
    func handleNoteUpdated(_ note:Note) {
        guard let index =  self.notes.firstIndex(where: { $0.note.id == note.id }) else { return }
        self.notes[index] = NoteAndBoard(note: note, board: self.notes[index].board)
        self.collectionNode.performBatchUpdates({
            self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
        }, completion: nil)
    }
    
    func handleNoteDeleted(_ note:Note) {
        guard let index =  self.notes.firstIndex(where: { $0.note.id == note.id }) else { return }
        self.notes.remove(at: index)
        self.collectionNode.performBatchUpdates({
            self.collectionNode.deleteItems(at: [IndexPath(row: index, section: 0)])
        }, completion: nil)
    }
}


//extension SearchNotesView: ASCollectionDataSource {
//
//    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
//        return 1
//    }
//
//    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
//        let count = self.notes.count
//        if count == 0 && self.keyword.isNotEmpty {
//            collectionNode.setEmptyMessage("没有找到相关的便签",y: 100)
//        }else {
//            collectionNode.clearEmptyMessage()
//        }
//        return count
//    }
//
//    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
//        let note = self.notes[indexPath.row]
//        let itemSize = self.itemContentSize
//        return {
//            let node =  NoteCellNode(note: note.note,itemSize: itemSize,board: note.board)
//            node.delegate = self
//            node.callbackBoardButtonTapped = { note,board in
//                self.callbackCellBoardButtonTapped?(note,board)
//            }
//            return node
//        }
//    }
//
//}

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
        let menuStyle = note.status == NoteBlockStatus.trash ? NoteMenuDisplayMode.trash : NoteMenuDisplayMode.list
        NoteMenuViewController.show(mode: menuStyle, note: note,sourceView: sender,delegate: self)
    }
    
    
}

//MARK: NoteMenuViewControllerDelegate
extension SearchNotesView:NoteMenuViewControllerDelegate {
    func noteMenuArchive(note: Note) {
        self.handleNoteUpdated(note)
    }
    
    func noteMenuMoveToTrash(note: Note) {
        self.handleNoteUpdated(note)
    }
    
    func noteMenuChooseBoards(note: Note) {
        
    }
    
    func noteMenuBackgroundChanged(note: Note) {
//        guard let row = self.notes.firstIndex(where: {$0.note.id == note.id}) else { return }
//        self.notes[row] = NoteAndBoard(note: note, board: self.notes[row].board)
//        if let noteCell = collectionNode.nodeForItem(at: IndexPath(row: row, section: 0)) as? NoteCellNode {
//            noteCell.note = note
//            noteCell.setupBackBackground()
//        }
    }
    
    func noteMenuDataMoved(note: Note) {
        self.handleNoteUpdated(note)
//        guard let board  = note.board else { return }
//        let message = board.type == BoardType.user.rawValue ? (board.icon + board.title) : board.title
//        self.showToast("便签已移动至：\"\(message)\"")
    }
    
    func noteMenuDataRestored(note: Note) {
        self.handleNoteUpdated(note)
    }
    
    func noteMenuDeleteTapped(note: Note) {
        let alert = UIAlertController(title: "删除便签", message: "你确定要彻底删除该便签吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "彻底删除", style: .destructive, handler: { _ in
            
//            NoteRepo.shared.deleteNote(noteId: note.id)
//                .subscribe(onNext: { _ in
//                    self.handleNoteDeleted(note)
//                }, onError: { error in
//                    Logger.error(error)
//                },onCompleted: {
//                })
//                .disposed(by: self.disposeBag)
            
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel,handler: nil))
        self.controller?.present(alert, animated: true)
    }
    
}



extension SearchNotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let note = self.notes[indexPath.row]
        self.openEditorVC(note: note.note)
    }
}

// float buttons
extension SearchNotesView {
    
    func openEditorVC(note: Note,isNew:Bool = false) {
//        let noteVC  = EditorViewController()
//        noteVC.mode = isNew ? EditorMode.create(noteInfo: note) :  EditorMode.browser(noteInfo: note)
//        noteVC.callbackNoteUpdate = {updateMode in
//            self.noteEditorUpdated(mode: updateMode)
//        }
//        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
}
