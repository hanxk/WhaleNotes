//
//  NotesView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import CHTCollectionViewWaterfallLayout
import RealmSwift
import SnapKit
import AsyncDisplayKit


protocol NotesViewDelegate: AnyObject {
    func didSelectItemAt(note:Note,indexPath: IndexPath)
}

class NotesView: UIView {
    
    weak var delegate: NotesViewDelegate?
    
    enum NotesViewConstants {
        static let cellSpace: CGFloat = 8
        static let cellHorizontalSpace: CGFloat = 12
    }
    
    private lazy var  layoutDelegate = WaterfallCollectionLayoutDelegate().then {
        $0.layoutInfo = WaterfallCollectionLayoutInfo(numberOfColumns: 2, columnSpacing: 12, interItemSpacing: 8, sectionInsets: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12), scrollDirection: ASScrollDirectionVerticalDirections)
    }
    
    
    private(set) lazy var collectionNode = ASCollectionNode(layoutDelegate: layoutDelegate, layoutFacilitator: nil).then { [weak self] in
        guard let self = self else {return}
        $0.alwaysBounceVertical = true
        let _layoutInspector = layoutDelegate
        $0.dataSource = self
        $0.delegate = self
        $0.layoutInspector = _layoutInspector
        //        $0.registerSupplementaryNode(ofKind: UICollectionView.elementKindSectionHeader)
    }
    
    
    private var notesResult:Results<Note>!
    //    private var notesClone:[NoteClone] = []
    //    private var notes:Results<Note>?
    //    private var cardsSize:[String:CGFloat] = [:]
    private var notesToken:NotificationToken?
    private var columnCount = 0
    private var cardWidth:CGFloat = 0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.columnCount = 2
        let validWidth = UIScreen.main.bounds.width - NotesViewConstants.cellHorizontalSpace*2 - NotesViewConstants.cellSpace*CGFloat(columnCount-1)
        self.cardWidth = validWidth / CGFloat(columnCount)
        self.setupUI()
        self.setupData()
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        collectionNode.frame = self.frame
        self.addSubnode(collectionNode)
    }
    
    private func setupData() {
        self.notesResult = DBManager.sharedInstance.getAllNotes()
//        notesResult.observe { [weak self] (changes: RealmCollectionChange) in
//            guard let self = self else { return }
//            switch changes {
//            case .initial:
//                self.collectionNode.reloadData()
//            case .update(_, let deletions, let insertions, let modifications):
//                self.collectionNode.performBatchUpdates({
//                    // 更新数据源
//                    self.collectionNode.insertItems(at: insertions.map({ IndexPath(row: $0, section: 0)}))
//                    self.collectionNode.deleteItems(at: deletions.map({ IndexPath(row: $0, section: 0)}))
//                    self.collectionNode.reloadItems(at: modifications.map({ IndexPath(row: $0, section: 0)}))
//                }, completion: nil)
//                break
//            case .error(let error):
//                fatalError("\(error)")
//            }
//        }
    }
}

extension NotesView {
    
    func viewWillAppear(_ animated: Bool) {
        
        print(String(self.notesResult.count))
    }
    
    
    func viewWillDisappear(_ animated: Bool) {
        //        notesToken?.invalidate()
        print(String(self.notesResult.count))
    }
    
    func noteEditorUpdated(mode:EditorUpdateMode) {
        switch mode {
         case .insert(let note):
            if let index = self.notesResult.index(of: note) {
                self.collectionNode.performBatchUpdates({
                    self.collectionNode.insertItems(at: [IndexPath(row: index, section: 0)])
                }, completion: nil)
            }
        case .update(let note):
            if let index = self.notesResult.index(of: note) {
                self.collectionNode.performBatchUpdates({
                    self.collectionNode.reloadItems(at: [IndexPath(row: index, section: 0)])
                }, completion: nil)
            }
       case .delete(let note):
            break
        }
    }
}

extension NotesView {
    
    func createNote(createMode: CreateMode) -> Note{
        let note = self.generateNote(createMode: createMode)
        DBManager.sharedInstance.addNote(note)
        
        return note
    }
    
    fileprivate func generateNote(createMode: CreateMode) -> Note {
        let note: Note = Note()
        note.titleBlock = Block.newTitleBlock()
        switch createMode {
        case .text:
            note.textBlock = Block.newTextBlock()
            break
        case .todo:
            note.todoBlocks.append(Block.newTodoGroupBlock())
            break
        case .attachment(let blocks):
            note.attachBlocks.append(objectsIn: blocks)
            break
        }
        return note
    }
}


extension NotesView: ASCollectionDataSource {
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.notesResult.count
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let note = self.notesResult[indexPath.row]
        let title = note.titleBlock?.text ?? ""
        let text = note.textBlock?.text ?? ""
        var todosRef:ThreadSafeReference<List<Block>>?
        if note.attachBlocks.isEmpty {
            todosRef = ThreadSafeReference(to: note.todoBlocks)
        }
        return {
            return NoteCellNode(title: title, text: text, todosRef: todosRef)
        }
    }
}


extension NotesView: ASCollectionDelegate {
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let note = self.notesResult[indexPath.row]
        self.delegate?.didSelectItemAt(note: note, indexPath: indexPath)
    }
}

