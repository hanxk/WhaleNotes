//
//  NotesView.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift
import AsyncDisplayKit

class NotesListView: UIView {
    
    private lazy var disposeBag = DisposeBag()
    private var notes:[NoteInfo]  = []
    private var selectedNoteId:String?
    private lazy var tableView = ASTableNode().then {
        $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: HomeViewController.toolbarHeight+20, right: 0)
        $0.backgroundColor = .clear
        $0.view.allowsSelection = false
        $0.view.separatorStyle = .none
        $0.view.keyboardDismissMode = .onDrag
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    private func setupUI() {
        tableView.frame = self.frame
        tableView.backgroundColor = .bg
        self.addSubnode(tableView)
        
        self.loadData()
    }
    
    private func loadData() {
        NoteRepo.shared.getNotes()
            .subscribe(onNext: { [weak self] notes in
                if let self = self {
                    self.notes = notes
                    self.tableView.reloadData()
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func createNewNote() {
        let noteInfo = NoteInfo(note: Note())
        NoteRepo.shared.createNote(noteInfo)
            .subscribe(onNext: { [weak self] noteInfo in
                if let self = self {
                    self.selectedNoteId = noteInfo.id
                    self.notes.insert(noteInfo, at: 0)
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
        
    }
}

extension NotesListView:ASTableDelegate {
    
}

extension NotesListView:ASTableDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        
        let noteInfo = self.notes[indexPath.row]
        let isEditing = noteInfo.note.id == (selectedNoteId ?? "")
        let node = NoteCardNode(noteInfo:noteInfo, isEditing: isEditing,action: { [weak self] action in
            self?.handleCardAction(action,noteId: noteInfo.note.id)
        })
        node.textChanged {[weak node] (newText: String) in
            UIView.performWithoutAnimation {
                node?.setNeedsLayout()
                print("哈哈哈r")
            }
        }
        node.textEdited {[weak self] text,editViewTag in
            self?.handleEditText(text: text, editViewTag: editViewTag, noteId: noteInfo.note.id)
        }
        return node
    }
    
    func  handleCardAction(_  action: NoteCardAction,noteId:String) {
        switch action {
        case .edit:
            self.handleEditAction(noteId: noteId)
            break
        case .save:
            self.handleSaveAction()
            break
        default:
            break
        }
    }
    
    private func handleEditAction(noteId:String) {
        guard let newIndex =  self.notes.firstIndex(where: {$0.note.id == noteId}) else { return }
        
        var rows =  [IndexPath(row: newIndex, section: 0)]
        if let selectedNoteId = self.selectedNoteId,
           let oldIndex =  self.notes.firstIndex(where: {$0.note.id == selectedNoteId}){
           rows.append(IndexPath(row: oldIndex, section: 0))
        }
        self.selectedNoteId = noteId
        self.tableView.reloadRows(rows: rows)
    }
    
    private func handleSaveAction() {
        
        guard let selectedNoteId = self.selectedNoteId,
           let oldIndex =  self.notes.firstIndex(where: {$0.note.id == selectedNoteId}) else { return }
        
//        let noteInfo = self.notes[oldIndex]
//        if noteInfo.note.createdAt == noteInfo.note.updatedAt && noteInfo.isEmpty  {
//            self.deleteNoteInfo(noteInfo: noteInfo)
//        }
        self.selectedNoteId = nil
        self.tableView.reloadRows(rows: [IndexPath(row: oldIndex, section: 0)])
    }
    
    private func handleEditText(text:String,editViewTag:EditViewTag,noteId:String) {
        guard var noteInfo = self.notes.first(where: { $0.id ==  noteId }) else { return }
        switch editViewTag {
        case .title:
            noteInfo.note.title  = text
        case .content:
            noteInfo.note.content  = text
        }
        if noteInfo.note.createdAt == noteInfo.note.updatedAt && noteInfo.isEmpty  {
            self.deleteNoteInfo(noteInfo: noteInfo)
        }else {
            self.updateNoteInfo(note: noteInfo.note)
        }
    }
    
    private func deleteNoteInfo(noteInfo:NoteInfo)  {
        NoteRepo.shared.deleteNote(noteInfo)
            .subscribe(onNext: { [weak self]  in
                guard let self = self else { return }
                guard let noteIndex = self.notes.firstIndex(where: { $0.id ==  noteInfo.id }) else { return }
                self.notes.remove(at: noteIndex)
                self.tableView.deleteRows(at: [IndexPath(row: noteIndex, section: 0)], with: .automatic)
                
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    private func updateNoteInfo(note:Note)  {
        NoteRepo.shared.updateNote(note)
            .subscribe(onNext: { [weak self] note in
                guard let self = self else { return }
                guard let noteIndex = self.notes.firstIndex(where: { $0.id ==  note.id }) else { return }
                var noteInfo  = self.notes[noteIndex]
                noteInfo.note = note
                
                self.notes[noteIndex] = noteInfo
                if self.selectedNoteId == nil{
                    self.tableView.reloadRows(at: [IndexPath(row: noteIndex, section: 0)], with: .none)
                }
                
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}

extension ASTableNode {
    func reloadData(animated: Bool) {
        self.reloadData(animated: animated, completion: nil)
    }

    func reloadData(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        self.performBatch(animated: animated, updates: {
            self.reloadData()
        }, completion: completion)
    }

    func reloadSections(animated: Bool = false, sections: IndexSet, rowAnimation: UITableView.RowAnimation = .none, completion: ((Bool) -> Void)? = nil) {
        self.performBatch(animated: animated, updates: {
            self.reloadSections(sections, with: rowAnimation)
        }, completion: completion)
    }

    func reloadRows(rows: [IndexPath], rowAnimation: UITableView.RowAnimation = .none, completion: ((Bool) -> Void)?  = nil) {
        let animated = rowAnimation != .none
        self.performBatch(animated: animated, updates: {
            self.reloadRows(at: rows, with: rowAnimation)
        }, completion: completion)
    }
}
