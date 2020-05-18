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
    
    
    private lazy var  flowNodesLayout = MosaicCollectionViewLayout().then {
        $0.numberOfColumns = 2;
        $0.delegate = self
        $0.headerHeight = 0;
        
        let horizontalSpace = NotesViewConstants.cellHorizontalSpace
        let verticalSpace = NotesViewConstants.cellSpace
        $0._sectionInset = UIEdgeInsets.init(top: verticalSpace, left: horizontalSpace, bottom: verticalSpace, right: horizontalSpace)
        $0.interItemSpacing = UIEdgeInsets.init(top: 10.0, left: 0, bottom: 10.0, right: 0)
    }
    
    private(set) lazy var collectionNode = ASCollectionNode(frame: CGRect.zero,collectionViewLayout:flowNodesLayout).then { [weak self] in
        guard let self = self else {return}
        $0.alwaysBounceVertical = true
        let _layoutInspector = MosaicCollectionViewLayoutInspector()
        $0.delegate = self
        $0.dataSource = self
        $0.layoutInspector = _layoutInspector
        
    }
    
    
    private var notesResult:Results<Note>!
    private var notesClone:[NoteClone] = []
    //    private var notes:Results<Note>?
    private var cardsSize:[String:CGFloat] = [:]
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
        notesToken = notesResult.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.cloneNotes()
                self.calcCardSize()
                self.collectionNode.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                self.collectionNode.performBatchUpdates({
                    // 更新数据源
                    self.updateDataSource(deletions: deletions, insertions: insertions, modifications: modifications)
                    self.collectionNode.insertItems(at: insertions.map({ IndexPath(row: $0, section: 0)}))
                    self.collectionNode.deleteItems(at: deletions.map({ IndexPath(row: $0, section: 0)}))
                    self.collectionNode.reloadItems(at: modifications.map({ IndexPath(row: $0, section: 0)}))
                }, completion: nil)
                break
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
}

extension NotesView {
    
    func viewWillAppear(_ animated: Bool) {
        
    }
    
    private func cloneNotes() {
        self.notesClone.removeAll()
        self.notesClone = self.notesResult.map({
            return NoteClone(id: $0.id, title: $0.titleBlock?.text ?? "", text: $0.textBlock?.text ?? "", updateAt: $0.updateAt)
        })
    }
    
    func viewWillDisappear(_ animated: Bool) {
        //        notesToken?.invalidate()
    }
    
    private func updateDataSource(deletions: [Int], insertions: [Int], modifications: [Int]) {
        self.cloneNotes()
        for index in insertions.sorted(by: >) {
            let note = notesClone[index]
            let cardHeight = NoteCardCell.calculateHeight(cardWidth: cardWidth, note: note)
            let key = generateCardSizeKey(note: note)
            cardsSize[key] = cardHeight
        }
        
        for index in modifications.sorted(by: >) {
            let note = notesClone[index]
            let cardHeight = NoteCardCell.calculateHeight(cardWidth: cardWidth, note: note)
            let key = generateCardSizeKey(note: note)
            cardsSize[key] = cardHeight
        }
    }
    
    private func calcCardSize() {
        for (_,note) in notesClone.enumerated() {
            let key = generateCardSizeKey(note: note)
            if cardsSize[key] == nil {
                let cardHeight = NoteCardCell.calculateHeight(cardWidth: cardWidth, note: note)
                cardsSize[key] = cardHeight
            }
        }
    }
    
    private func generateCardSizeKey(note: NoteClone) -> String {
        return String(note.updateAt.timeIntervalSince1970) + "*" + note.id
    }
}

extension NotesView: MosaicCollectionViewLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView, layout: MosaicCollectionViewLayout, originalItemSizeAtIndexPath: IndexPath) -> CGSize {
        
        let cardHeight = self.cardsSize[generateCardSizeKey(note: notesClone[originalItemSizeAtIndexPath.row])] ?? 0
        let size = CGSize(width: cardWidth, height: cardHeight)
        
        return size
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        let note = self.notesClone[indexPath.row]
        Logger.info(Thread.current.isMainThread ? "mail" : "----> child")
        return {
            return NoteCellNode(title: note.title, text: note.text)
        }
    }
    
}


extension NotesView: ASCollectionDataSource {
    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        return 1
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return notesClone.count
    }
    
}


