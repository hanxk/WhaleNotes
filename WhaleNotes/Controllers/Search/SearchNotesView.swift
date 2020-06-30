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
    
    private let usecase = NotesUseCase()
    private let editorUseCase = NoteRepo.shared
    
    private var selectedIndexPath:IndexPath?
    
    var callbackCellBoardButtonTapped:((Note)->Void)?
    
    private var notes:[Note] = [] {
        didSet {
            self.collectionNode.reloadData()
        }
    }
    
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
    
    
    func generateCollectionView(mode:DisplayMode) -> ASCollectionNode {
       return ASCollectionNode(collectionViewLayout:collectionLayout).then { [weak self] in
             guard let self = self else {return}
             $0.alwaysBounceVertical = true
             $0.dataSource = self
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
        if keyword.isEmpty {
            self.notes = []
            return
        }
        
        NoteRepo.shared.searchNotes(keyword: keyword)
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    self.notes = $0
                }
            }, onError: {
                Logger.error($0)
            })
        .disposed(by: disposeBag)
    }
    
}

extension SearchNotesView {
    
    func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    func viewWillDisappear(_ animated: Bool) {
        //        notesToken?.invalidate()
    }
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
        //
        switch mode {
        case .insert(let noteInfo):
//            if self.checkBoardIsDel(noteInfo)  {
//                return
//            }
//            sectionNoteInfo.notes.insert(noteInfo, at: 0)
//            self.collectionNode.performBatchUpdates({
//                self.collectionNode.insertItems(at: [IndexPath(row: 0, section: 0)])
//            }, completion: nil)
            break
        case .update(let noteInfo):
            break
//            if self.checkBoardIsDel(noteInfo)  {
//                return
//            }
//
//            if let row = noteInfos.firstIndex(where: { $0.rootBlock.id == noteInfo.rootBlock.id }) {
//
//                sectionNoteInfo.notes[row] = noteInfo
//                self.collectionNode.performBatchUpdates({
//                    self.collectionNode.reloadItems(at: [IndexPath(row: row, section: 0)])
//                }, completion: nil)
//            }
        case .delete(let note):
//            self.handleDeleteNote(note)
             break
        case .moved(let note):
//             self.noteMenuDataMoved(note: note)?
             break
        }
    }
    
    
    func handleDeleteNote(_ note:Note) {
//        if let row = noteInfos.firstIndex(where: { $0.rootBlock.id == note.rootBlock.id }) {
//            sectionNoteInfo.notes.remove(at: row)
//            self.collectionNode.performBatchUpdates({
//                self.collectionNode.deleteItems(at: [IndexPath(row: row, section: 0)])
//            }, completion: nil)
//        }
    }
}


extension SearchNotesView: ASCollectionDataSource {
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.notes.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let note = self.notes[indexPath.row]
        let itemSize = self.itemContentSize
        return {
            let node =  NoteCellNode(note: note,itemSize: itemSize,isShowBoard: true)
            node.delegate = self
            node.callbackBoardButtonTapped = { note in
                self.callbackCellBoardButtonTapped?(note)
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
        NoteMenuViewController.show(mode: .list, note: note,sourceView: sender,delegate: self)
    }
    
    
}

//MARK: NoteMenuViewControllerDelegate
extension SearchNotesView:NoteMenuViewControllerDelegate {
    func noteMenuArchive(note: Note) {
        self.handleDeleteNote(note)
    }
    
    func noteMenuMoveToTrash(note: Note) {
        self.handleDeleteNote(note)
//        self.showToast("便签已移动至废纸篓")
    }
    
    func noteMenuChooseBoards(note: Note) {
        
    }
    
    func noteMenuBackgroundChanged(note: Note) {
        guard let row = self.notes.firstIndex(where: {$0.id == note.id}) else { return }
        self.notes[row] = note
        if let noteCell = collectionNode.nodeForItem(at: IndexPath(row: row, section: 0)) as? NoteCellNode {
            noteCell.note = note
            noteCell.setupBackBackground()
        }
    }
    
    func noteMenuDataMoved(note: Note) {
        self.handleDeleteNote(note)
        
        if note.boards.isEmpty { return }
        let board = note.boards[0]
        
        let message = board.type == BoardType.user.rawValue ? (board.icon+board.title) : board.title
        self.showToast("便签已移动至：\"\(message)\"")
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
    
    func openEditorVC(note: Note,isNew:Bool = false) {
        let noteVC  = EditorViewController()
        noteVC.mode = isNew ? EditorMode.create(noteInfo: note) :  EditorMode.browser(noteInfo: note)
        noteVC.callbackNoteUpdate = {updateMode in
            self.noteEditorUpdated(mode: updateMode)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
}
