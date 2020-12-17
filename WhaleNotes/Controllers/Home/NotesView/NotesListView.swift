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
    
    private var notes:[NoteInfo]  = [NoteInfo(note: Note(id: "asd", content: "哈哈哈哈", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd2", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd3",title: "这是一个标题", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd4", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd5", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd6", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd7", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd8", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd9", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd10", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date())),
                                     NoteInfo(note: Note(id: "asd11", content: "人们越来越把互联网甚至云服务当成理所当然的基础设施，仿佛就像水和电一样，然后搭建了许多依赖它们的东西……但可靠性还是不够吧。在电不可靠的时候人们还能上备用电源，网断了有时候勉强还能靠移动网络，而云服务挂了那就完全没得用了吧", createdAt: Date(), updatedAt: Date()))
    ]
    private var selectedNoteId:String?
    private lazy var tableView = ASTableNode().then {
        $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: HomeViewController.toolbarHeight+20, right: 0)
        $0.backgroundColor = .clear
        
        $0.view.allowsSelection = false
        $0.view.separatorStyle = .none
        
        $0.view.keyboardDismissMode = .onDrag
//        $0.showsVerticalScrollIndicator = false
//        $0.register(NoteCardCell.self, forCellReuseIdentifier: NoteCardCell.className)
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
        self.tableView.reloadRows(animated: false, rows: rows)
    }
    
    private func handleSaveAction() {
        
        guard let selectedNoteId = self.selectedNoteId,
           let oldIndex =  self.notes.firstIndex(where: {$0.note.id == selectedNoteId}) else { return }
        
        self.selectedNoteId = nil
        self.tableView.reloadRows(animated: false, rows: [IndexPath(row: oldIndex, section: 0)])
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

    func reloadSections(animated: Bool, sections: IndexSet, rowAnimation: UITableView.RowAnimation = .none, completion: ((Bool) -> Void)? = nil) {
        self.performBatch(animated: animated, updates: {
            self.reloadSections(sections, with: rowAnimation)
        }, completion: completion)
    }

    func reloadRows(animated: Bool, rows: [IndexPath], rowAnimation: UITableView.RowAnimation = .none, completion: ((Bool) -> Void)?  = nil) {
        self.performBatch(animated: animated, updates: {
            self.reloadRows(at: rows, with: rowAnimation)
        }, completion: completion)
    }
}
