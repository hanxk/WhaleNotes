//
//  NoteMenuViewController.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import UIKit
import RxSwift


enum NoteMenuType {
    case pin
    case copy
    case move
    case background
    case info
    case trash
}

class NoteMenuViewController: ContextMenuViewController {
    
    
    var note:Note!
//    var boards:[Board] = []
    
    typealias NoteMenuUpdateCallback = ((Note,NoteMenuType)->Void)
    
    var callbackNoteUpdated:NoteMenuUpdateCallback?
    let disposeBag = DisposeBag()
    
    static let menuWidth:CGFloat = 200
    
    static func show(note:Note,sourceView:UIView,callback:NoteMenuUpdateCallback?) {
        let menuVC =  NoteMenuViewController()
        menuVC.note = note
        menuVC.callbackNoteUpdated = callback
        menuVC.showContextMenu(sourceView: sourceView)
    }
    
    
    convenience init() {
        self.init(nibName:nil, bundle:nil)
        self.menuWidth = NoteMenuViewController.menuWidth
        self.items = [
            ContextMenuItem(label: "置顶", icon: "pin", tag: NoteMenuType.pin),
            ContextMenuItem(label: "复制到", icon: "square.on.square", tag: NoteMenuType.copy),
            ContextMenuItem(label: "移动至", icon: "arrow.right.to.line.alt", tag: NoteMenuType.move,isNeedJump: true),
            ContextMenuItem(label: "背景色", icon: "paintbrush", tag: NoteMenuType.background,isNeedJump: true),
            ContextMenuItem(label: "时间信息", icon: "info.circle", tag: NoteMenuType.info,isNeedJump: true),
            ContextMenuItem(label: "移到废纸篓", icon: "trash", tag: NoteMenuType.trash),
        ]
        self.itemTappedCallback = { menuItem,vc in
            guard let tag = menuItem.tag as? NoteMenuType else { return }
            switch tag {
            case .pin:
                break
            case .copy:
                let chooseBoardVC = ChooseBoardViewController()
                vc.navigationController?.pushViewController(chooseBoardVC, animated: true)
                break
            case .move:
                let chooseBoardVC = ChooseBoardViewController()
                vc.navigationController?.pushViewController(chooseBoardVC, animated: true)
                break
            case .background:
                let colorVC = NoteColorViewController()
                colorVC.callbackColorChoosed = { color in
                    self.handleUpdateBackground(color)
                }
                vc.navigationController?.pushViewController(colorVC, animated: true)
                break
            case .info:
                let dateVC = NoteDateViewController()
                dateVC.note = self.note
                vc.navigationController?.pushViewController(dateVC, animated: true)
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
                self.callbackNoteUpdated?(newNote, NoteMenuType.background)

                self.dismiss()
                
            }, onError: { error in
                Logger.error(error)
            })
        .disposed(by: disposeBag)
        
    }
}
