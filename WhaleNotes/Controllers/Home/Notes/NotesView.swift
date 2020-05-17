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


protocol NotesViewDelegate: AnyObject {
    func didSelectItemAt(note:Note,indexPath: IndexPath)
}

class NotesView: UIView {
    
    weak var delegate: NotesViewDelegate?
    
    enum NotesViewConstants {
        static let cellSpace: CGFloat = 8
        static let cellHorizontalSpace: CGFloat = 12
    }
    
    private let flowLayout = CHTCollectionViewWaterfallLayout().then {
        $0.minimumColumnSpacing = NotesViewConstants.cellSpace
        $0.minimumInteritemSpacing = NotesViewConstants.cellSpace
    }
    
    private(set) lazy var collectionView = UICollectionView(frame: CGRect.zero,collectionViewLayout: flowLayout).then { [weak self] in
        guard let self = self else {return}
        $0.delegate = self
        $0.dataSource = self
        $0.register(NoteCardCell.self, forCellWithReuseIdentifier:"NoteCardCell")
        $0.backgroundColor = .white
        $0.alwaysBounceVertical = true
    }
    
//    private var notes:[Note] = []
    private var notes:Results<Note>?
    private var cardsSize:[String:CGFloat] = [:]
    private var notesToken:NotificationToken?
    private var columnCount = 0
    private var cardWidth:CGFloat = 0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.columnCount = 2
        let validWidth = UIScreen.main.bounds.width - NotesViewConstants.cellHorizontalSpace*2 - NotesViewConstants.cellSpace*CGFloat(columnCount-1)
        self.cardWidth = validWidth / CGFloat(columnCount)
        
        self.setupUI()
        self.setupData()
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(NotesViewConstants.cellHorizontalSpace)
            make.trailing.equalToSuperview().offset(-NotesViewConstants.cellHorizontalSpace)
        }
    }
}

extension NotesView {
    
    func viewWillAppear(_ animated: Bool) {
        notesToken = notes?.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            let collectionView = self.collectionView
            switch changes {
            case .initial:
                self.calcCardSize()
                collectionView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                collectionView.performBatchUpdates({
                    // 更新数据源
                    self.updateDataSource(deletions: deletions, insertions: insertions, modifications: modifications)
                    
                    collectionView.insertItems(at: insertions.map({ IndexPath(row: $0, section: 0)}))
                    collectionView.deleteItems(at: deletions.map({ IndexPath(row: $0, section: 0)}))
                    collectionView.reloadItems(at: modifications.map({ IndexPath(row: $0, section: 0)}))
                    
                }, completion: nil)
            case .error(let error):
                // An error occurred while opening the Realm file on the background worker thread
                fatalError("\(error)")
            }
        }
    }
    func viewWillDisappear(_ animated: Bool) {
        notesToken?.invalidate()
    }
    
    private func setupData() {
        let notesResult = DBManager.sharedInstance.getAllNotes()
        self.notes = notesResult
    }

    
    private func updateDataSource(deletions: [Int], insertions: [Int], modifications: [Int]) {
        guard let notes = self.notes else { return }
        for index in insertions.sorted(by: >) {
            let note = notes[index]
            let cardHeight = NoteCardCell.calculateHeight(cardWidth: cardWidth, note: note)
            let key = generateCardSizeKey(note: note)
            cardsSize[key] = cardHeight
        }
        
        for index in modifications.sorted(by: >) {
            let note = notes[index]
            let cardHeight = NoteCardCell.calculateHeight(cardWidth: cardWidth, note: note)
            let key = generateCardSizeKey(note: note)
            cardsSize[key] = cardHeight
        }
    }
    
    private func calcCardSize() {
        guard let notes = self.notes else { return }
        for (_,note) in notes.enumerated() {
            let key = generateCardSizeKey(note: note)
            if cardsSize[key] == nil {
                let cardHeight = NoteCardCell.calculateHeight(cardWidth: cardWidth, note: note)
                cardsSize[key] = cardHeight
            }
        }
    }
    
    private func generateCardSizeKey(note: Note) -> String {
        return String(note.updateAt.timeIntervalSince1970) + "*" + note.id
    }
}

extension NotesView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NoteCardCell", for: indexPath) as! NoteCardCell
        cell.note = self.notes![indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}


extension NotesView: CHTCollectionViewDelegateWaterfallLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let notes = notes else { return .zero }
        let cardHeight = self.cardsSize[generateCardSizeKey(note: notes[indexPath.row])] ?? 0
        return CGSize(width: cardWidth, height: cardHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, columnCountFor section: Int) -> Int {
        return columnCount
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard  let notes = self.notes else { return }
        delegate?.didSelectItemAt(note: notes[indexPath.row], indexPath: indexPath)
        
    }
}
