//
//  NoteMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift
import Toast_Swift


enum NoteEditorAction {
    case pin
    case archive
    case move
    case background
    case trash
    case deleteBlock(blockType:BlockType)
    
    //废纸篓
    case restore
    case delete
    
}


struct NoteMenuItem  {
    var label: String
    var icon: String
    var menuType:NoteEditorAction
}

enum NoteMenuDisplayMode {
    case detail
    case list
    case trash
}

//protocol NoteMenuViewControllerDelegate: AnyObject {
//
//    func noteMenuMoveToTrash(note: NoteInfo)
//    func noteMenuBackgroundChanged(note:NoteInfo)
//    func noteMenuArchive(note: NoteInfo)
//
//    func noteBlockDelete(blockType:BlockType)
//
//    func noteMenuMoveTapped(note: NoteInfo)
//    func noteMenuDeleteTapped(note: NoteInfo)
//    func noteMenuDataRestored(note: NoteInfo)
//}
//
//extension NoteMenuViewControllerDelegate {
//
//    func noteMenuMoveToTrash(note: NoteInfo){}
//    func noteMenuBackgroundChanged(note:NoteInfo){}
//    func noteMenuArchive(note: NoteInfo){}
//    func noteBlockDelete(blockType:BlockType) {}
//
//
//    func noteMenuMoveTapped(note: NoteInfo){}
//    func noteMenuDeleteTapped(note: NoteInfo){}
//    func noteMenuDataRestored(note: NoteInfo){}
//}



class NoteMenuViewController: ContextMenuViewController {
    
//    var note:NoteInfo!
//    var properties:BlockNoteProperty {
//        get { return note.properties }
//        set { note.properties = newValue}
//    }
//
//    var mode:NoteMenuDisplayMode! {
//        didSet {
//            self.setupMenus()
//        }
//    }
//    var callback:((NoteEditorAction) -> Void)!
//
//
//    typealias NoteMenuUpdateCallback = ((Note,NoteEditorAction)->Void)
//
//    var callbackNoteUpdated:NoteMenuUpdateCallback?
//
//    let disposeBag = DisposeBag()
//
//    static let menuWidth:CGFloat = 200
//
//    convenience init() {
//        self.init(nibName:nil, bundle:nil)
//        self.menuWidth = NoteMenuViewController.menuWidth
//    }
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//
//    private func setupMenus() {
//
//        self.setupMenuItems()
//
//        self.itemTappedCallback = { menuItem,menuVC in
//            guard let tag = menuItem.tag as? NoteEditorAction else { return}
//            self.callback(tag)
//        }
//    }
//
//    static func generateNoteMenuItems(noteInfo:NoteInfo) -> [NoteMenuItem] {
//        if noteInfo.status == .trash {
//            return [
//                NoteMenuItem(label: "恢复", icon: "arrow.up.bin", menuType: .restore),
//                NoteMenuItem(label: "彻底删除", icon: "trash", menuType: .delete)
//            ]
//        }
//
//        let archiveTitle = noteInfo.status == .archive ? "取消归档" : "归档"
//
//        return [
//            NoteMenuItem(label: archiveTitle, icon: "archivebox", menuType: .archive),
//            NoteMenuItem(label: "移动", icon: "arrowshape.turn.up.right", menuType: .move),
//            NoteMenuItem(label: "背景", icon: "paintbrush", menuType: .background),
//            NoteMenuItem(label: "删除", icon: "trash", menuType: .trash)
//        ]
//    }
//
//    private func setupMenuItems() {
//        if self.mode == NoteMenuDisplayMode.trash {
//            let menuItems = [
//                ContextMenuItem(label: "恢复", icon: "arrow.up.bin", tag: NoteEditorAction.restore),
//                ContextMenuItem(label: "彻底删除", icon: "trash", tag: NoteEditorAction.delete),
//            ]
//            self.items.append((SectionMenuItem(id: 1),menuItems))
//            return
//        }
//
//        let archiveTitle = self.note.status == NoteBlockStatus.archive ? "取消归档" : "归档"
//        let menuItems = [
//            ContextMenuItem(label: archiveTitle, icon: "archivebox", tag: NoteEditorAction.archive),
//            ContextMenuItem(label: "移动至...", icon: "arrow.right.to.line.alt", tag: NoteEditorAction.move),
//            ContextMenuItem(label: "背景色", icon: "paintbrush", tag: NoteEditorAction.background),
//            ContextMenuItem(label: "移到废纸篓", icon: "trash", tag: NoteEditorAction.trash),
//        ]
//        self.items.append((SectionMenuItem(id: 1),menuItems))
//
//    }
    
}

extension NoteMenuViewController {
    
//    func handleUpdateBackground(_ color:NoteBackground) {
//        if note.properties.backgroundColor == color {
//            self.dismiss()
//            return
//        }
//        self.note.updatedAt = Date()
//        properties.backgroundColor = color
//        NoteRepo.shared.updateProperties(id: note.id, properties: properties)
//            .subscribe { _ in
//                self.delegate?.noteMenuBackgroundChanged(note: self.note)
//                self.dismiss()
//            } onError: {
//                Logger.error($0)
//            }
//            .disposed(by: disposeBag)
//    }
//
//    private func move2Trash() {
//        self.updateNoteStates(status: .trash) {
//            self.delegate?.noteMenuMoveToTrash(note: $0)
//        }
//    }
//
//
//    private func archivenNote() {
//        var status = self.note.noteBlock.blockNoteProperties!.status
//        status = (status == .archive) ? .normal : .archive
//        self.updateNoteStates(status: status) {
//            self.delegate?.noteMenuArchive(note: $0)
//        }
//    }
    
    
//    private func updateNoteStates(status:NoteBlockStatus,callback:@escaping (NoteInfo) -> Void) {
//        guard var newNote = self.note
//              else { return }
//        newNote.updatedAt = Date()
//        newNote.noteBlock.blockNoteProperties?.status =  status
//        NoteRepo.shared.updateProperties(id: newNote.id, properties: newNote.noteBlock.blockNoteProperties!)
//            .subscribe { _ in
//                callback(newNote)
//            } onError: {
//                Logger.error($0)
//            }
//            .disposed(by: disposeBag)
//    }
}



extension NoteMenuViewController {
//    func restoreNote() {
//        guard var newNote = self.note
//              else { return }
//        newNote.noteBlock.blockNoteProperties?.status = .normal
//        NoteRepo.shared.updateProperties(id: newNote.id, properties: newNote.noteBlock.blockNoteProperties!)
//            .subscribe { _ in
//                self.delegate?.noteMenuDataRestored(note: newNote)
//            } onError: {
//                Logger.error($0)
//            }
//            .disposed(by: disposeBag)
//
//    }
//
//    func deleteNote() {
//        guard let note = self.note  else { return }
//        self.delegate?.noteMenuDeleteTapped(note: note)
//    }
}
