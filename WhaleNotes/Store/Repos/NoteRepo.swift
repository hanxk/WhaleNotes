//
//  NoteRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class NoteRepo:BaseRepo {
    static let shared = NoteRepo()
}

extension NoteRepo {
    func getNotes(tag:String = "") -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes:[Note]
                if tag.isEmpty {
                    notes = try self.noteDao.query()
                }else {
                   notes = try self.noteDao.query(tagId: tag)
                }
                // 获取所有note的tags
                let noteTags = try self.tagDao.queryByTag()
                var noteInfos:[NoteInfo] = []
                for note in notes {
                    let tags = noteTags.filter{$0.0 == note.id}.map { $0.1 }
                    noteInfos.append(NoteInfo(note: note, tags: tags))
                }
                return noteInfos
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func getNote(id:String) -> Observable<NoteInfo?> {
        return Observable<NoteInfo?>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> NoteInfo? in
                guard let note = try self.noteDao.query(id: id) else { return nil }
                // 获取所有note的tags
                let tags = try self.tagDao.queryByNote(noteId: note.id)
                return NoteInfo(note: note, tags: tags)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func createNote(_ noteInfo:NoteInfo) -> Observable<NoteInfo> {
        return Observable<NoteInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> NoteInfo in
                try self.noteDao.insert(noteInfo.note)
                return noteInfo
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updateNote(_ note:Note) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                var newNote = note
                newNote.updatedAt = Date()
                try self.noteDao.update(newNote)
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func updateNoteTitle(_ note:Note,newTitle:String) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                var newNote = note
                newNote.title = newTitle
                newNote.updatedAt = Date()
                try self.noteDao.updateTitle(newTitle, noteId: note.id,updatedAt: newNote.updatedAt)
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updateNoteContent(_ note:Note,newContent:String) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                var newNote = note
                newNote.content  = newContent
                newNote.updatedAt = Date()
                try self.noteDao.updateContent(newContent, noteId: note.id,updatedAt: newNote.updatedAt)
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func deleteNote(_ noteInfo:NoteInfo) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.noteDao.delete(noteInfo.id)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}


extension NoteRepo {
    func getTags() -> Observable<[Tag]> {
        return Observable<[Tag]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [Tag] in
                let tags = try self.tagDao.query()
                return tags
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    func getValidTags() -> Observable<[Tag]> {
        return Observable<[Tag]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [Tag] in
                let tags = try self.tagDao.queryValids()
                return tags
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func searchTags(_ keyword: String) -> Observable<[Tag]> {
        return Observable<[Tag]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [Tag] in
                let tags = try self.tagDao.search(keyword)
                return tags
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func updateNoteTags(noteId:String,tags:[String]) -> Observable<Void>  {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.noteTagDao.delete(noteId:noteId)
                try tags.forEach {
                    try self.noteTagDao.insert(NoteTag(noteId: noteId, tagId: $0))
                }
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func deleteNoteTag(note:Note,tagId:String) -> Observable<Note>  {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                try self.noteTagDao.delete(noteId: note.id, tagId:tagId)
                // 更新 note update time
                var newNote = note
                newNote.updatedAt = Date()
                try self.noteDao.updateUpdatedAt(id: note.id,updatedAt: newNote.updatedAt)
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createTag(_ tag:Tag,note:Note?) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.tagDao.insert(tag)
                if let note = note {
                        var newNote = note
                        newNote.updatedAt = Date()
                        // 更新 note update time
                        try self.noteDao.updateUpdatedAt(id: newNote.id, updatedAt: newNote.updatedAt)
                    try self.noteTagDao.insert(NoteTag(noteId: newNote.id, tagId: tag.id))
                }
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func createNoteTag(note:Note,tagId:String) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tagId))
                var newNote = note
                newNote.updatedAt = Date()
                // 更新 note update time
                try self.noteDao.updateUpdatedAt(id: note.id, updatedAt: newNote.updatedAt)
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}
