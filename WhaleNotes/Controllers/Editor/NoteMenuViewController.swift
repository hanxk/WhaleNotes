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


enum NoteMenuType {
    case pin
    case archive
    case move
    case background
    case info
    case trash
}


enum NoteTrashMenuType {
    case restore
    case delete
}


protocol NoteMenuViewControllerDelegate: AnyObject {
    func noteMenuDataMoved(note: Note)
    func noteMenuMoveToTrash(note: Note)
    func noteMenuBackgroundChanged(note:Note)
    func noteMenuArchive(note: Note)
}


protocol NoteMenuViewControllerTrashDelegate: AnyObject {
    func noteMenuDeleteTapped(note: Note)
    func noteMenuDataRestored(note: Note)
}

class NoteMenuViewController: ContextMenuViewController {
    
    var note:Note!
    
    weak var delegate:NoteMenuViewControllerDelegate? {
        didSet {
            self.setupMenus()
        }
    }
    weak var trashDelegate:NoteMenuViewControllerTrashDelegate? {
        didSet {
            self.setupTrashMenus()
        }
    }
    
    typealias NoteMenuUpdateCallback = ((Note,NoteMenuType)->Void)
    
    var callbackNoteUpdated:NoteMenuUpdateCallback?
    
    let disposeBag = DisposeBag()
    
    static let menuWidth:CGFloat = 200
    
    static func show(note:Note,sourceView:UIView,delegate:NoteMenuViewControllerDelegate) {
        let menuVC =  NoteMenuViewController()
        menuVC.note = note
        menuVC.delegate = delegate
        menuVC.showContextMenu(sourceView: sourceView)
    }
    
    static func showTrashMenu(note:Note,sourceView:UIView,delegate:NoteMenuViewControllerTrashDelegate) {
        let menuVC =  NoteMenuViewController()
        menuVC.note = note
        menuVC.trashDelegate = delegate
        menuVC.showContextMenu(sourceView: sourceView)
    }
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        self.menuWidth = NoteMenuViewController.menuWidth
    }
    
    
    private func setupMenus() {
        
        let archiveTitle = note.status == NoteBlockStatus.archive ? "取消归档" : "归档"
        
        self.items = [
//            ContextMenuItem(label: "置顶", icon: "arrow.up.to.line.alt", tag: NoteMenuType.pin),
            ContextMenuItem(label: archiveTitle, icon: "archivebox", tag: NoteMenuType.archive),
            ContextMenuItem(label: "移动至...", icon: "arrow.right.to.line.alt", tag: NoteMenuType.move,isNeedJump: true),
            ContextMenuItem(label: "背景色", icon: "paintbrush", tag: NoteMenuType.background,isNeedJump: true),
            ContextMenuItem(label: "显示信息", icon: "info.circle", tag: NoteMenuType.info,isNeedJump: true),
            ContextMenuItem(label: "移到废纸篓", icon: "trash", tag: NoteMenuType.trash),
        ]
        self.itemTappedCallback = { menuItem,menuVC in
            guard let tag = menuItem.tag as? NoteMenuType else { return }
            switch tag {
            case .pin:
                break
            case .archive:
                self.archivenNote()
                break
            case .move:
                let vc = ChangeBoardViewController()
                vc.note = self.note
                vc.callbackBoardChoosed = { board in
                    self.handleMove2Board(board: board)
                }
                menuVC.navigationController?.pushViewController(vc, animated: true)
                break
            case .background:
                let colorVC = NoteColorViewController()
                colorVC.selectedColor = self.note.backgroundColor
                colorVC.callbackColorChoosed = { color in
                    self.handleUpdateBackground(color)
                }
                menuVC.navigationController?.pushViewController(colorVC, animated: true)
                break
            case .info:
                let dateVC = NoteDateViewController()
                dateVC.note = self.note
                menuVC.navigationController?.pushViewController(dateVC, animated: true)
                break
            case .trash:
                self.move2Trash()
                break
            }
        }
    }
    
    private func setupTrashMenus() {
        self.items = [
            ContextMenuItem(label: "恢复", icon: "arrow.up.bin", tag: NoteTrashMenuType.restore),
            ContextMenuItem(label: "彻底删除", icon: "trash", tag: NoteTrashMenuType.delete),
        ]
        self.itemTappedCallback = { menuItem,menuVC in
            guard let tag = menuItem.tag as? NoteTrashMenuType else { return }
            switch tag {
            case .restore:
                self.restoreNote()
                break
            case .delete:
                self.deleteNote()
                break
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

extension NoteMenuViewController {
    func handleUpdateBackground(_ color:String) {
        if note.backgroundColor == color {
            self.dismiss()
            return
        }
        note.backgroundColor = color
        guard var block = note.rootBlock else { return }
        block.updatedAt = Date()
        NoteRepo.shared.updateBlock(block: block)
            .subscribe(onNext: { block in
                var newNote = self.note!
                newNote.rootBlock = block
//                self.callbackNoteUpdated?(newNote, NoteMenuType.background)
                self.delegate?.noteMenuBackgroundChanged(note: newNote)
                
                self.dismiss()
                
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        
    }
    func handleMove2Board(board:Board) {
        NoteRepo.shared.moveNote2Board(note: self.note, board: board)
            .subscribe(onNext: { [weak self] in
                if let self = self {
                    self.dismiss()
                    self.delegate?.noteMenuDataMoved(note: $0)
                }
            }, onError:{ error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
    }
    
    private func move2Trash() {
        guard var noteBlock = self.note.rootBlock else { return }
        noteBlock.status = NoteBlockStatus.trash.rawValue
        updateNoteBlock(noteBlock: noteBlock) {
            self.delegate?.noteMenuMoveToTrash(note: $0)
        }
    }
    
    private func archivenNote() {
        guard var noteBlock = self.note.rootBlock else { return }
        noteBlock.status = self.note.status == NoteBlockStatus.normal  ? NoteBlockStatus.archive.rawValue : NoteBlockStatus.normal.rawValue
        updateNoteBlock(noteBlock: noteBlock) {
            self.delegate?.noteMenuArchive(note: $0)
        }
    }
    
    
    private func updateNoteBlock(noteBlock:Block,callback:@escaping (Note)->Void) {
        NoteRepo.shared.updateBlock(block: noteBlock)
            .subscribe(onNext: {
                var newNote = self.note!
                 newNote.rootBlock = $0
                callback(newNote)
            }, onError: { error in
                Logger.error(error)
            })
        .disposed(by: disposeBag)
    }
}



extension NoteMenuViewController {
    func restoreNote() {
        guard var noteBlock = self.note.rootBlock else { return }
        noteBlock.status = NoteBlockStatus.normal.rawValue
        NoteRepo.shared.updateBlock(block: noteBlock)
            .subscribe(onNext: {
                var newNote = self.note!
                newNote.rootBlock = $0
                self.trashDelegate?.noteMenuDataRestored(note: self.note)
            }, onError: { error in
                Logger.error(error)
            },onCompleted: {
                self.dismiss()
            })
        .disposed(by: disposeBag)
    }
    
    func deleteNote() {
        self.trashDelegate?.noteMenuDeleteTapped(note: self.note)
    }
}
