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
    case deleteBlock(blockType:BlockType)
    
    //废纸篓
    case restore
    case delete
    
}

enum NoteMenuDisplayMode {
    case detail
    case list
    case trash
}

protocol NoteMenuViewControllerDelegate: AnyObject {
    func noteMenuDataMoved(note: Note)
    func noteMenuMoveToTrash(note: Note)
    func noteMenuBackgroundChanged(note:Note)
    func noteMenuArchive(note: Note)
    
    func noteBlockDelete(blockType:BlockType)
    
    func noteMenuDeleteTapped(note: Note)
    func noteMenuDataRestored(note: Note)
}

extension NoteMenuViewControllerDelegate {
    func noteMenuDataMoved(note: Note){}
    func noteMenuMoveToTrash(note: Note){}
    func noteMenuBackgroundChanged(note:Note){}
    func noteMenuArchive(note: Note){}
    func noteBlockDelete(blockType:BlockType) {}
}

// 废纸篓
extension NoteMenuViewControllerDelegate {
    func noteMenuDeleteTapped(note: Note) {}
    func noteMenuDataRestored(note: Note) { }
}

class NoteMenuViewController: ContextMenuViewController {
    
    var note:Note!
    var mode:NoteMenuDisplayMode!
    
    weak var delegate:NoteMenuViewControllerDelegate? {
        didSet {
            self.setupMenus()
        }
    }
    
    typealias NoteMenuUpdateCallback = ((Note,NoteMenuType)->Void)
    
    var callbackNoteUpdated:NoteMenuUpdateCallback?
    
    let disposeBag = DisposeBag()
    
    static let menuWidth:CGFloat = 200
    
    static func show(mode:NoteMenuDisplayMode, note:Note,sourceView:UIView,delegate:NoteMenuViewControllerDelegate) {
        let menuVC =  NoteMenuViewController()
        menuVC.note = note
        menuVC.mode = mode
        menuVC.delegate = delegate
        menuVC.showContextMenu(sourceView: sourceView)
    }
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        self.menuWidth = NoteMenuViewController.menuWidth
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func setupMenus() {
        
        self.setupMenuItems()
        
        self.itemTappedCallback = { menuItem,menuVC in
            guard let tag = menuItem.tag as? NoteMenuType else { return}
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
            case .deleteBlock(let blockType):
//                self.deleteBlock(blockType)
                self.delegate?.noteBlockDelete(blockType: blockType)
                break
            case .restore:
                self.restoreNote()
                break
            case .delete:
                self.deleteNote()
                break
            }
        }
    }
    
    private func setupMenuItems() {
        if self.mode == NoteMenuDisplayMode.trash {
            let menuItems = [
                ContextMenuItem(label: "恢复", icon: "arrow.up.bin", tag: NoteMenuType.restore),
                ContextMenuItem(label: "彻底删除", icon: "trash", tag: NoteMenuType.delete),
            ]
            self.items.append((SectionMenuItem(id: 1),menuItems))
            return
        }
        
        let archiveTitle = note.status == NoteBlockStatus.archive ? "取消归档" : "归档"
        let menuItems = [
            ContextMenuItem(label: archiveTitle, icon: "archivebox", tag: NoteMenuType.archive),
            ContextMenuItem(label: "移动至...", icon: "arrow.right.to.line.alt", tag: NoteMenuType.move,isNeedJump: true),
            ContextMenuItem(label: "背景色", icon: "paintbrush", tag: NoteMenuType.background,isNeedJump: true),
            ContextMenuItem(label: "显示信息", icon: "info.circle", tag: NoteMenuType.info,isNeedJump: true),
            ContextMenuItem(label: "移到废纸篓", icon: "trash", tag: NoteMenuType.trash),
        ]
        self.items.append((SectionMenuItem(id: 1),menuItems))
        
        if mode == NoteMenuDisplayMode.detail {
            var secondItems:[ContextMenuItem] = []
            if note.textBlock != nil {
                secondItems.append(ContextMenuItem(label: "删除 \"文本\"", icon: "textbox", tag: NoteMenuType.deleteBlock(blockType: BlockType.text)))
            }
            if note.rootTodoBlock != nil {
                secondItems.append(ContextMenuItem(label: "删除 \"待办事项\"", icon: "checkmark.square", tag: NoteMenuType.deleteBlock(blockType: BlockType.todo)))
            }
            if note.attachmentBlocks.isNotEmpty {
                secondItems.append(ContextMenuItem(label: "删除 \"图片集\"", icon: "photo.on.rectangle", tag: NoteMenuType.deleteBlock(blockType: BlockType.image)))
            }
            
            if secondItems.isNotEmpty {
                self.items.append((SectionMenuItem(id: 2),secondItems))
            }
        }
        
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
                self.delegate?.noteMenuBackgroundChanged(note: newNote)
                self.dismiss()
                
            }, onError: { error in
                Logger.error(error)
            })
            .disposed(by: disposeBag)
        
    }
    func handleMove2Board(board:Board?) {
        guard let board = board else {
            self.dismiss()
            return
        }
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
                self.delegate?.noteMenuDataRestored(note: newNote)
            }, onError: { error in
                Logger.error(error)
            },onCompleted: {
                self.dismiss()
            })
        .disposed(by: disposeBag)
    }
    
    func deleteNote() {
        self.delegate?.noteMenuDeleteTapped(note: self.note)
    }
}
