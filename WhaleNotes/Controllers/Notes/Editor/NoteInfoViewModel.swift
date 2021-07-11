//
//  NoteInfoViewModel.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/24.
//  Copyright © 2020 hanxk. All rights reserved.
//
import Foundation
import RxSwift


enum NoteEditorEvent {
    case updated(noteInfo:NoteInfo)
    case fileUpdated(noteInfo:NoteInfo)
//    case statusChanged(block:BlockInfo)
//    case backgroundChanged(block:BlockInfo)
//    case moved(block:BlockInfo,boardBlock:BlockInfo)
//    case delete(block:BlockInfo)
}
//
//
//enum ContentUpdateEvent {
//    case insterted(content:BlockInfo)
//    case deleted(content:BlockInfo)
//    case updated(content:BlockInfo)
//}

class NoteInfoViewModel {
    public let noteInfoPub: PublishSubject<NoteEditorEvent> = PublishSubject()
    private let disposeBag = DisposeBag()
    private(set) var noteInfo: NoteInfo!
    private var note: Note {
        get  {
            return self.noteInfo.note
        }
        set {
            self.noteInfo.note = newValue
        }
    }
    
    init(noteInfo: NoteInfo) {
        self.noteInfo = noteInfo
    }
    
    func updateNote(_ note:Note)  {
        NoteRepo.shared.updateNote(note)
            .subscribe(onNext: { [weak self] note in
                guard let self = self else { return }
                self.note = note
                self.noteInfoPub.onNext(.updated(noteInfo: self.noteInfo))
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func updateNoteTitle(title:String)  {
        NoteRepo.shared.updateNoteTitle(self.note, newTitle: title)
            .subscribe(onNext: { [weak self] note in
                guard let self = self else { return }
                self.note = note
                self.noteInfoPub.onNext(.updated(noteInfo: self.noteInfo))
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func updateNoteContent(content:String)  {
        NoteRepo.shared.updateNoteContent(self.note, newContent: content)
            .subscribe(onNext: { [weak self] note in
                guard let self = self else { return }
                self.note = note
                self.noteInfoPub.onNext(.updated(noteInfo: self.noteInfo))
//                callback?(note)
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    func updateNoteStatus(status:NoteStatus)  {
        NoteRepo.shared.updateNoteStatus(self.note, status: status)
            .subscribe(onNext: { [weak self] note in
                guard let self = self else { return }
                self.note = note
                self.noteInfoPub.onNext(.updated(noteInfo: self.noteInfo))
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    func updateNoteAndTags(note:Note,tagTitles:[String])  {
        NoteRepo.shared.updateNoteAndTags(self.noteInfo, note: note, tagTitles: tagTitles)
            .subscribe(onNext: { [weak self] noteInfo in
                guard let self = self else { return }
                self.noteInfo = noteInfo
                self.noteInfoPub.onNext(.updated(noteInfo: noteInfo))
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
    
    func saveImage(fileInfo:FileInfo)  {
        NoteRepo.shared.saveImage(fileInfo: fileInfo,noteInfo: self.noteInfo)
            .subscribe(onNext: { [weak self] noteInfo in
                guard let self = self,let noteInfo = noteInfo else { return }
                self.noteInfo = noteInfo
                self.noteInfoPub.onNext(.fileUpdated(noteInfo: self.noteInfo))
            }, onError: {
                Logger.error($0)
            })
            .disposed(by: disposeBag)
    }
    
}
