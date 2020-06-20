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
    case copy
    case move
    case background
    case info
    case trash
}


protocol NoteMenuViewControllerDelegate: AnyObject {
    func noteMenuDataMoved(note: Note)
    func noteMenuBackgroundChanged(note:Note)
//    func noteMenuChooseBoards(note: Note)
}

class NoteMenuViewController: ContextMenuViewController {
    
    var note:Note!
    weak var delegate:NoteMenuViewControllerDelegate?
    
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
    
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        self.menuWidth = NoteMenuViewController.menuWidth
        self.items = [
            ContextMenuItem(label: "置顶", icon: "arrow.up.to.line.alt", tag: NoteMenuType.pin),
            ContextMenuItem(label: "复制", icon: "square.on.square", tag: NoteMenuType.copy),
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
            case .copy:
                let chooseBoardVC = ChooseBoardViewController()
                menuVC.navigationController?.pushViewController(chooseBoardVC, animated: true)
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
}
