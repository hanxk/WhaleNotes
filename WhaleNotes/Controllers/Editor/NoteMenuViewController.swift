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
    
    func noteMenuMoveToTrash(note: NoteInfo)
    func noteMenuBackgroundChanged(note:NoteInfo)
    func noteMenuArchive(note: NoteInfo)
    
    func noteBlockDelete(blockType:BlockType)
    
    func noteMenuMoveTapped(note: NoteInfo)
    func noteMenuDeleteTapped(note: NoteInfo)
    func noteMenuDataRestored(note: NoteInfo)
}

extension NoteMenuViewControllerDelegate {
    
    func noteMenuMoveToTrash(note: NoteInfo){}
    func noteMenuBackgroundChanged(note:NoteInfo){}
    func noteMenuArchive(note: NoteInfo){}
    func noteBlockDelete(blockType:BlockType) {}
    
    
    func noteMenuMoveTapped(note: NoteInfo){}
    func noteMenuDeleteTapped(note: NoteInfo){}
    func noteMenuDataRestored(note: NoteInfo){}
}



class NoteMenuViewController: ContextMenuViewController {
    
    var note:NoteInfo!
    var properties:BlockNoteProperty {
        get { return note.properties }
        set { note.properties = newValue}
    }
    
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
    
    static func show(mode:NoteMenuDisplayMode, note:NoteInfo,sourceView:UIView,delegate:NoteMenuViewControllerDelegate) {
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
//                self.archivenNote()
                break
            case .move:
                self.delegate?.noteMenuMoveTapped(note: self.note)
//                let vc = ChangeBoardViewController()
//                vc.noteBlock = self.note.noteBlock
////                vc.callbackBoardChoosed = { board in
////                    self.handleMove2Board(board: board)
////                }
//                menuVC.navigationController?.pushViewController(vc, animated: true)
                break
            case .background:
                let colorVC = NoteColorViewController()
                colorVC.selectedColor = self.note.properties.backgroundColor
                colorVC.callbackColorChoosed = { color in
                    self.handleUpdateBackground(color)
                }
                menuVC.navigationController?.pushViewController(colorVC, animated: true)
                break
            case .info:
                let dateVC = NoteDateViewController()
                dateVC.noteBlock = self.note.noteBlock
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
        
        let archiveTitle = self.note.status == NoteBlockStatus.archive ? "取消归档" : "归档"
        let menuItems = [
            ContextMenuItem(label: archiveTitle, icon: "archivebox", tag: NoteMenuType.archive),
            ContextMenuItem(label: "移动至...", icon: "arrow.right.to.line.alt", tag: NoteMenuType.move),
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
            if note.todoGroupBlock != nil {
                secondItems.append(ContextMenuItem(label: "删除 \"待办事项\"", icon: "checkmark.square", tag: NoteMenuType.deleteBlock(blockType: BlockType.todo)))
            }
            if note.attachmentGroupBlock != nil {
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
        if note.properties.backgroundColor == color {
            self.dismiss()
            return
        }
        self.note.updatedAt = Date()
        properties.backgroundColor = color
        NoteRepo.shared.updateProperties(id: note.id, properties: properties)
            .subscribe { _ in
                self.delegate?.noteMenuBackgroundChanged(note: self.note)
                self.dismiss()
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposeBag)
    }
    
    private func move2Trash() {
        guard var newNote = self.note
              else { return }
        newNote.updatedAt = Date()
        newNote.noteBlock.blockNoteProperties?.status = .trash
        NoteRepo.shared.updateProperties(id: newNote.id, properties: newNote.noteBlock.blockNoteProperties!)
            .subscribe { _ in
                self.delegate?.noteMenuMoveToTrash(note: newNote)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposeBag)
    }
    
    
    private func archivenNote() {
//        guard var noteBlock = self.note.rootBlock else { return }
//        noteBlock.blockNoteProperties!.status = self.note.status == .normal  ? .archive : .normal
//        updateNoteBlock(noteBlock: noteBlock) {
//            self.delegate?.noteMenuArchive(note: $0)
//        }
    }
    
    
    private func updateNoteBlock(noteBlock:Block,callback:@escaping (Note)->Void) {
//        NoteRepo.shared.updateBlock(block: noteBlock)
//            .subscribe(onNext: {
//                var newNote = self.note!
//                 newNote.rootBlock = $0
//                callback(newNote)
//            }, onError: { error in
//                Logger.error(error)
//            })
//        .disposed(by: disposeBag)
    }
}



extension NoteMenuViewController {
    func restoreNote() {
        guard var newNote = self.note
              else { return }
        newNote.noteBlock.blockNoteProperties?.status = .normal
        NoteRepo.shared.updateProperties(id: newNote.id, properties: newNote.noteBlock.blockNoteProperties!)
            .subscribe { _ in
                self.delegate?.noteMenuDataRestored(note: newNote)
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposeBag)
        
    }
    
    func deleteNote() {
        guard let note = self.note  else { return }
        self.delegate?.noteMenuDeleteTapped(note: note)
//        guard let note = self.note  else { return }
//        NoteRepo.shared.deleteBlockInfo(blockId: note.id)
//            .subscribe { _ in
//                self.delegate?.noteD
//            } onError: {
//                Logger.error($0)
//            }
//            .disposed(by: disposeBag)
    }
}
