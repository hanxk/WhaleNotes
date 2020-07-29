//
//  NoteInfoViewModel.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift


enum EditorUpdateEvent {
    case updated(noteInfo:NoteInfo)
    case statusChanged(noteInfo:NoteInfo)
    case backgroundChanged(noteInfo:NoteInfo)
    case moved(noteInfo:NoteInfo,boardBlock:BlockInfo)
    case delete(noteInfo:NoteInfo)
}

class NoteEidtorMenuModel {
   
    private(set) var model: NoteInfo
    public let noteInfoPub: PublishSubject<EditorUpdateEvent> = PublishSubject()
    private let disposable = DisposeBag()
    
    var callback:((NoteInfo) -> Void)!

    init(model: NoteInfo) {
        self.model = model
    }
    
    func update(status:NoteBlockStatus) {
        var properties = model.properties
        properties.status = status
        self.updateProperties(properties) {
            self.noteInfoPub.onNext(EditorUpdateEvent.statusChanged(noteInfo: self.model))
        }
    }
    
    func update(background:String) {
        var properties = model.properties
        properties.backgroundColor = background
        self.updateProperties(properties) {
           self.noteInfoPub.onNext(EditorUpdateEvent.backgroundChanged(noteInfo: self.model))
        }
    }
    
    func moveBoard(boardBlock:BlockInfo) {
        NoteRepo.shared.moveToBoard(note: model.noteBlock, boardId: boardBlock.id)
            .subscribe {newNoteBlock in
                self.model.noteBlock = newNoteBlock
                self.noteInfoPub.onNext(EditorUpdateEvent.moved(noteInfo: self.model,boardBlock:boardBlock))
                
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposable)
    }
    
    private func updateProperties(_ properties:BlockNoteProperty,callback:@escaping ()->Void) {
        NoteRepo.shared.updateProperties(id: model.id, properties: properties)
            .subscribe { _ in
                self.model.properties = properties
                self.model.updatedAt = Date()
                callback()
            } onError: {
                Logger.error($0)
            }
            .disposed(by: disposable)
    }
    
    func delete() {
        NoteRepo.shared.deleteNote(noteId: model.id,noteFiles: self.extractNoteFiles())
            .subscribe(onNext: { _  in
                self.noteInfoPub.onNext(.delete(noteInfo: self.model))
//                self.isCancelNotify = true
//                self.navigationController?.popViewController(animated: true)
//                self.callbackNoteUpdate?(EditorUpdateMode.deleted(noteInfo: self.note))
            },onError: {
                Logger.error($0)
            })
            .disposed(by: disposable)
    }
    
    private func extractNoteFiles() -> [String] {
       guard let blocks = model.attachmentGroupBlock?.contentBlocks else { return [] }
       return blocks.map { $0.blockImageProperties!.url }
    }
    
//    private func handleNoteInfoUpdate(action:NoteEditorAction) {
//        switch action {
//        case .pin:
//            break
//        case .archive:
//            self.update(status: .archive)
//            break
//        case .move:
////            self.openChooseBoardVC(model: noteInfoModel)
//            break
//        case .background:
////            self.openChooseBackgroundVC(model: noteInfoModel)
//            break
//        case .trash:
//            self.update(status: .trash)
//            break
//        case .deleteBlock:
//            break
//        case .restore:
//            self.update(status: .normal)
//            break
//        case .delete:
//            break
//        }
//    }
//
    
    private func publish(event:EditorUpdateEvent) {
//        self.callback(self.model)
    }
}
