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
    
//    private let editorUseCase = NoteRepo.shared
    
    private var selectedIndexPath:IndexPath?
//    private var trashedNotes:[(Board,[Note])] = [] {
//        didSet {
//            btnNewNote.isHidden = trashedNotes.isEmpty
//        }
//    }
    
    var delegate:NotesViewDelegate?
    
    
    
    let btnNewNote = NotesView.makeFloatButton().then {
        $0.tintColor = .white
        $0.backgroundColor = UIColor(hexString: "#EC4D3D")
        $0.isHidden = true
        
        let config = UIImage.SymbolConfiguration(pointSize: FloatButtonConstants.iconSize, weight: .light)
        $0.setImage(UIImage(systemName: "bin.xmark",withConfiguration:config )?.withTintColor(.white), for: .normal)
        $0.addTarget(self, action: #selector(btnClearTapped), for: .touchUpInside)
    }
    
    
    
    private var numberOfColumns = 2
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: Int(numberOfColumns), columnSpacing:  NotesViewConstants.waterfall_cellSpace, interItemSpacing: NotesViewConstants.waterfall_cellSpace, sectionInsets: UIEdgeInsets(top: 0, left: NotesViewConstants.waterfall_cellHorizontalSpace, bottom: 12, right:  NotesViewConstants.waterfall_cellHorizontalSpace), scrollDirection: ASScrollDirectionVerticalDirections)
    }
    
    private lazy var collectionLayout =  UICollectionViewFlowLayout().then {
        
        $0.itemSize = NotesView.getItemSize(numberOfColumns: self.numberOfColumns)
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
                $0.contentInset = UIEdgeInsets(top: 0, left: NotesViewConstants.cellHorizontalSpace, bottom: 160, right: NotesViewConstants.cellHorizontalSpace)
                $0.showsVerticalScrollIndicator = false
                $0.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
                
            }
        case .grid:
            return ASCollectionNode(collectionViewLayout:collectionLayout).then { [weak self] in
                guard let self = self else {return}
                $0.alwaysBounceVertical = true
                $0.dataSource = self
                $0.delegate = self
                $0.contentInset = UIEdgeInsets(top: -6, left: NotesViewConstants.cellHorizontalSpace, bottom: 160, right: NotesViewConstants.cellHorizontalSpace)
                $0.showsVerticalScrollIndicator = false
                
                $0.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
                
            }
        }
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
        self.setupData()
    }
    
    
    private func setupUI() {
        collectionNode.frame = self.frame
        collectionNode.backgroundColor = .clear
        self.addSubnode(collectionNode)
        self.setupFloatButtons()
    }
    
    func setupFloatButtons() {
        
        let btnSize:CGFloat = FloatButtonConstants.btnSize
        self.addSubview(btnNewNote)
        btnNewNote.snp.makeConstraints { (make) -> Void in
            make.width.height.equalTo(btnSize)
            make.bottom.equalTo(self).offset(-FloatButtonConstants.bottom)
            make.trailing.equalTo(self).offset(-FloatButtonConstants.trailing)
        }
    }
    
    @objc func btnClearTapped() {
        let alert = UIAlertController(title: "清空废纸篓", message: "清空后的内容将不能够被恢复。确认要清空吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确认清空", style: .destructive, handler: { _ in
            self.clearTrash()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        self.controller?.present(alert, animated: true)
    }
    
    private func clearTrash() {
//        var noteIds:[String] = []
//        for data in self.trashedNotes {
//            noteIds.append(contentsOf:data.1.map { return $0.id} )
//        }
//        if noteIds.isEmpty {
//            return
//        }
//        NoteRepo.shared.deleteNotes(noteIds: noteIds)
//            .subscribe(onNext: { isSuccess in
//                if isSuccess {
//                    self.trashedNotes.removeAll()
//                    self.collectionNode.reloadData()
//                }
//            }, onError: {error in
//                Logger.error(error)
//            })
//            .disposed(by: disposeBag)
    }
    
    
    private func setupData() {
//        BoardRepo.shared.getBoardsExistsTrashNote()
//            .subscribe(onNext: { [weak self] in
//                if let self = self {
//                    self.trashedNotes = $0
//                    self.collectionNode.reloadData()
//                }
//            }, onError: {
//                Logger.error($0)
//            })
//            .disposed(by: disposeBag)
    }
    
}


extension TrashView: ASCollectionDataSource {
    
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
//        let count = self.trashedNotes.count
//        if count == 0 {
//            collectionNode.setEmptyMessage("暂无便签")
//        }else {
//            collectionNode.clearEmptyMessage()
//        }
//        return count
        return 0
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
//        return self.trashedNotes[section].1.count
        return 0
    }
    
//    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
////        let note = self.trashedNotes[indexPath.section].1[indexPath.row]
////        let itemSize = self.collectionLayout.itemSize
////        return {
////            let node =  NoteCellNode(note: note,itemSize: itemSize)
////            node.delegate = self
////            return node
////        }
//    }
    
    
    
//    func collectionNode(_ collectionNode: ASCollectionNode,
//                        nodeForSupplementaryElementOfKind kind: String,
//                        at indexPath: IndexPath) -> ASCellNode {
//        if kind == UICollectionView.elementKindSectionHeader {
//            return TrashHeaderNode(board: self.trashedNotes[indexPath.section].0,topPadding: 22)
//        } else {
//            let emptyNode: ASCellNode = ASCellNode()
//            emptyNode.style.minSize = CGSize(width: 0.01, height: 0.01)
//            return emptyNode
//        }
//    }
    
    
}


extension TrashView: ASCollectionDelegateFlowLayout {
    func collectionNode(_ collectionNode: ASCollectionNode, sizeRangeForHeaderInSection section: Int) -> ASSizeRange {
        return ASSizeRangeUnconstrained
    }
}


extension TrashView:NoteCellNodeDelegate {
    func noteCellImageBlockTapped(imageView: ASImageNode, note: Note) {
        let defaultImage: UIImage = imageView.image!
        let browser = PhotoViewerViewController(note: note)
        browser.transitionAnimator = JXPhotoBrowserZoomAnimator(previousView: { index -> UIView? in
            imageView.image = defaultImage
            return imageView.view
        })
        browser.callBackShowNoteButtonTapped = {
            //            if let indexPath = self.findNoteIndex(note)
            //            self.openEditorVC(note: self.noteInfos[])
            self.openEditorVC(note: note)
        }
        browser.show()
    }
    
    
    func noteCellBlockTapped(block: Block) {
        
    }
    
    func noteCellMenuTapped(sender: UIView,note:Note) {
        NoteMenuViewController.show(mode:.trash,note: note, sourceView: sender, delegate: self)
    }
    
    
}



//MARK: NoteMenuViewControllerDelegate
extension TrashView:NoteMenuViewControllerDelegate {
    func noteMenuDeleteTapped(note: Note) {
        let alert = UIAlertController(title: "删除便签", message: "你确定要彻底删除该便签吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "彻底删除", style: .destructive, handler: { _ in
            
//            NoteRepo.shared.deleteNote(noteId: note.id)
//                .subscribe(onNext: { isSuccess in
//                    self.removeNodeFromCollectionView(note)
//                }, onError: { error in
//                    Logger.error(error)
//                },onCompleted: {
//                })
//                .disposed(by: self.disposeBag)
            
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel,handler: nil))
        self.controller?.present(alert, animated: true)
    }
    
    func noteMenuDataRestored(note: Note) {
        self.removeNodeFromCollectionView(note)
    }
    
    private func  removeNodeFromCollectionView( _ note:Note) {
//        guard let indexPath = findNoteIndex(note) else { return }
//        self.trashedNotes[indexPath.section].1.remove(at: indexPath.row)
//
//        if self.trashedNotes[indexPath.section].1.isEmpty {
//            self.trashedNotes.remove(at: indexPath.section)
//            self.collectionNode.performBatchUpdates({
//                self.collectionNode.deleteSections(IndexSet([indexPath.section]))
//            }, completion: nil)
//            return
//        }
//        self.collectionNode.performBatchUpdates({
//            self.collectionNode.deleteItems(at: [indexPath])
//        }, completion: nil)
    }
    
    private func findNoteIndex(_ note:Note) -> IndexPath? {
//        for (index,data) in self.trashedNotes.enumerated() {
//            if let row =  data.1.firstIndex(where: {$0.id == note.id}) {
//                return IndexPath(row: row, section: index)
//            }
//        }
        return nil
    }
}

extension TrashView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
//        let note = self.trashedNotes[indexPath.section].1[indexPath.row]
//        self.openEditorVC(note: note)
    }
    
    func openEditorVC(note: Note,isNew:Bool = false) {
        let noteVC  = EditorViewController()
        noteVC.mode = EditorMode.browser(noteInfo: note)
        noteVC.callbackNoteUpdate = {updateMode in
            self.noteEditorUpdated(mode: updateMode)
        }
        self.controller?.navigationController?.pushViewController(noteVC, animated: true)
    }
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
        switch mode {
        case .delete(let note):
            self.removeNodeFromCollectionView(note)
        case .trashedOut(let note):
            self.removeNodeFromCollectionView(note)
        default:
            break
        }
    }
    
}
