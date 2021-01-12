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
import FloatingPanel


enum NoteListMode {
    case all
    case tag(tag:Tag)
    case trash
}

class NotesListView: UIView {
    
    private lazy var disposeBag = DisposeBag()
    private var notes:[NoteInfo]  = []
    private var tagTitleWidthCache:[String:CGFloat] = [:]
    private var selectedNoteId:String?
    private lazy var tableView = ASTableNode().then {
        $0.delegate = self
        $0.dataSource = self
        $0.contentInset = UIEdgeInsets(top: 5, left: 0, bottom: HomeViewController.toolbarHeight+20, right: 0)
        $0.backgroundColor = .clear
        $0.view.separatorStyle = .none
        $0.view.keyboardDismissMode = .onDrag
    }
    private var mode:NoteListMode!
    private var noteTag:Tag? = nil
    private weak var viewModel: NoteInfoViewModel?
    
    enum MenuAction:Int {
        case edit =  1
        case trash =  2
        case share =  3
        case copy =  4
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
    
    func loadData(mode:NoteListMode){
        self.mode = mode
        self.setupData(mode: mode)
    }
    
    
    private func setupData(mode:NoteListMode) {
        switch mode {
        case .all:
            self.loadData(status: .normal)
        case .tag(let tag):
            self.loadData(tag:tag)
        case .trash:
            self.loadData(status: .trash)
        }
    }
    
    func openEditorVC(noteInfo:NoteInfo,isNewCreated:Bool = false) {
        let editorVC  = MDEditorViewController()
        editorVC.noteInfo = noteInfo
        editorVC.isNewCreated = isNewCreated
        editorVC.callbackNoteInfoEdited {[weak self] noteInfo in
            self?.handleNoteInfoUpdated(noteInfo)
        }
//        editorVC.modalPresentationStyle = .fullScreen
//        self.controller?.present(editorVC, animated: true, completion: nil)
        self.controller?.navigationController?.pushViewController(editorVC, animated: true)
    }
}

//MARK: data handle
extension NotesListView {
    
    private func loadData(tag:Tag? = nil) {
        self.noteTag = tag
        let tagId = tag?.id ?? ""
        NoteRepo.shared.getNotes(tag: tagId)
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
    
    private func loadData(status:NoteStatus) {
        NoteRepo.shared.getNotes(status: status)
            .subscribe(onNext: { [weak self] notes in
                if let self = self {
                    self.notes = notes
                    self.tableView.reloadData()
                    self.tableView.contentOffset = .zero
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    
    func createNewNote() {
        var noteInfo = NoteInfo(note: Note())
        if let tag = self.noteTag {
            noteInfo.note.content = "#\(tag.title) "
            noteInfo.tags = [tag]
        }
        NoteRepo.shared.createNote(noteInfo)
            .subscribe(onNext: { [weak self] noteInfo in
                self?.handleNoteInfoCreated(noteInfo: noteInfo)
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
        
    }
    
    func handleNoteInfoCreated(noteInfo:NoteInfo) {
        
        let visibleRows = self.tableView.indexPathsForVisibleRows()
        
        self.notes.insert(noteInfo, at: 0)
        let indexPath:IndexPath = IndexPath(row: 0, section: 0)
        
        let needScroll2Top = visibleRows.count > 0 && visibleRows[0].row > indexPath.row
        
        self.tableView.insertRows(at: [indexPath], with: .automatic)
        if needScroll2Top {
            self.tableView.scrollToRow(at: indexPath, at: .none, animated: false)
        }
        self.openEditorVC(noteInfo:noteInfo,isNewCreated: true)
    }
}

extension NotesListView {
    func handleNoteInfoUpdated(_ noteInfo:NoteInfo) {
        // 检查tag
        if let tag = self.noteTag,
           noteInfo.tags.contains(where: {$0.id == tag.id}) == false
        {
            self.deleteNoteInfoFromDataSource(noteInfo: noteInfo)
            return
        }
        self.updateNoteInfo(noteInfo: noteInfo)
    }
    
    func updateNoteInfo(noteInfo:NoteInfo) {
        guard let index = self.notes.firstIndex(where: {$0.id == noteInfo.id}) else { return }
        self.notes[index] = noteInfo
        self.tableView.reloadRowsWithoutAnim(at: [IndexPath(row: index, section: 0)])
    }
    func deleteNoteInfoFromDataSource(noteInfo:NoteInfo) {
        guard let noteIndex = self.notes.firstIndex(where: { $0.id ==  noteInfo.id }) else { return }
        self.notes.remove(at: noteIndex)
        self.tableView.deleteRows(at: [IndexPath(row: noteIndex, section: 0)], with: .automatic)
    }
}

extension NotesListView:ASTableDelegate {
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        let noteInfo = self.notes[indexPath.row]
        self.openEditorVC(noteInfo: noteInfo)
    }
}

extension NotesListView:ASTableDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeForRowAt indexPath: IndexPath) -> ASCellNode {
        
        let noteInfo = self.notes[indexPath.row]
        let isEditing = noteInfo.note.id == (selectedNoteId ?? "")
        let tagTitlesWidth  = getTagsTitleWidth(tags: noteInfo.tags)
        let node = NoteCardNode(noteInfo:noteInfo, tagTitlesWidth: tagTitlesWidth, isEditing: isEditing,action: { [weak self] action in
            self?.handleCardAction(action,noteId: noteInfo.note.id)
        })
        node.textChanged {[weak node] (newText: String) in
            UIView.performWithoutAnimation {
                node?.setNeedsLayout()
            }
        }
        node.textEdited {[weak self] text,editViewTag in
            self?.handleEditText(text: text, editViewTag: editViewTag, noteId: noteInfo.note.id)
        }
        return node
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
    
    private func getTagsTitleWidth(tags:[Tag]) ->   [CGFloat]  {
        return  tags.map{
            if let  tagTitleWidth = self.tagTitleWidthCache[$0.title] {
                return tagTitleWidth
            }
            let w  = $0.title.width(withHeight: TagConfig.tagHeight, font: TagConfig.tagFont)
            self.tagTitleWidthCache[$0.title] = w
            return w
        }
    }
    
    private func handleSaveAction() {
        guard let selectedNoteId = self.selectedNoteId,
              let oldIndex =  self.notes.firstIndex(where: {$0.note.id == selectedNoteId}) else { return }
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
                self?.deleteNoteInfoFromDataSource(noteInfo: noteInfo)
                
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
                    self.tableView.reloadRowsWithoutAnim(at: [IndexPath(row: noteIndex, section: 0)])
                }
                
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}


//MARK: card action
extension NotesListView {
    func  handleCardAction(_  action: NoteCardAction,noteId:String) {
        switch action {
        case .edit:
            self.handleEditAction(noteId: noteId)
        case .save:
            self.handleSaveAction()
        case .menu:
            self.handleMenuAction(noteId:noteId)
        case .tag:
            self.handleTagAction(noteId:noteId)
        default:
            break
        }
    }
    
    fileprivate func handleMenuAction(noteId:String) {
        
        guard let index =  self.notes.firstIndex(where: {$0.note.id == noteId}) else { return }
        let noteInfo = self.notes[index]
        
        let trashRow = noteInfo.status == .normal ?
        PopMenuRow(icon: "trash", title: "移到废纸篓",tag:MenuAction.trash.rawValue) :
        PopMenuRow(icon: "arrow.up.bin", title: "恢复",tag:MenuAction.trash.rawValue)
        
        let menuRows = [
            trashRow,
            PopMenuRow(icon: "square.and.arrow.up", title: "分享",tag:MenuAction.share.rawValue),
            PopMenuRow(icon: "doc.on.doc", title: "复制",tag:MenuAction.copy.rawValue)
        ]
        let menuVC = PopMenuController(menuRows: menuRows)
        menuVC.rowSelected = {[weak self] menuRow in
            self?.handleMenuRowSelected(menuRow:menuRow,noteId: noteId)
        }
        menuVC.showModal(vc: self.controller!)
    }
    
    fileprivate func handleTagAction(noteId:String) {
        guard let noteInfo = self.notes.first(where: { $0.id ==  noteId }) else { return }
        let tag = ChooseTagViewController()
        tag.noteInfo = noteInfo
        tag.tagsChanged = { [weak self]  noteInfo in
            self?.updateNoteInfoDataSource(newNoteInfo: noteInfo)
        }
        self.controller?.present(UINavigationController(rootViewController: tag), animated: true, completion: nil)
    }
    
    fileprivate func updateNoteInfoDataSource(newNoteInfo:NoteInfo) {
        guard let newIndex =  self.notes.firstIndex(where: {$0.note.id == newNoteInfo.id}) else { return }
        let newIndexPath = IndexPath(row: newIndex, section: 0)
        
        // 通知sidemenu 更新
        if let tag = self.noteTag {
            let isTagDeleted = !newNoteInfo.tags.contains{$0.id == tag.id}
            if isTagDeleted {// tag 被移除
                self.notes.remove(at: newIndex)
                self.tableView.deleteRows(at: [newIndexPath], with: .none)
                return
            }
        }
        
        // 状态更新
        if self.notes[newIndex].status != newNoteInfo.status {
            // 刷新 tag
            if self.notes[newIndex].tags.count  > 0  {
                EventManager.shared.post(name: .Tag_CHANGED)
            }
            self.notes.remove(at: newIndex)
            self.tableView.deleteRows(at: [newIndexPath], with: .none)
            return
        }
        
        self.notes[newIndex] = newNoteInfo
        self.tableView.reloadRowsWithoutAnim(at: [newIndexPath])
    }
}


//MARK: card menu action
extension NotesListView {
    fileprivate func handleMenuRowSelected(menuRow:PopMenuRow,noteId:String) {
        guard let menuAcion = MenuAction(rawValue: menuRow.tag) else { return }
        switch menuAcion {
        case .edit:
            self.handleEditAction(noteId: noteId)
        case .trash:
            self.handleTrashAction(noteId: noteId)
        default:
            break
        }
    }
    
    private func handleTrashAction(noteId:String) {
        guard let index =  self.notes.firstIndex(where: {$0.note.id == noteId}) else { return }
        let note = self.notes[index]
        let status:NoteStatus = note.note.status == .normal ? .trash : .normal
        var noteinfo = note
        NoteRepo.shared.updateNoteStatus(note.note, status: status)
            .subscribe(onNext: { [weak self] note in
                noteinfo.note = note
                self?.updateNoteInfoDataSource(newNoteInfo: noteinfo)
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: 清空回收站
extension NotesListView {
    
    func clearTrash() {
        if self.notes.isEmpty {return}
        let alert = UIAlertController(title: "", message: "清空后的内容将不能够被恢复。确认要清空吗？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "确认清空", style: .destructive , handler:{ (UIAlertAction)in
            self.handleClearTrash()
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler:{ (UIAlertAction)in
            print("User click Dismiss button")
        }))
        self.controller?.present(alert, animated: true, completion:nil)
    }
    
    private func handleClearTrash() {
        NoteRepo.shared.removeTrashedNotes()
            .subscribe(onNext: { [weak self]  in
                if let self = self {
                    self.notes = []
                    self.tableView.reloadData()
                }
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
}
