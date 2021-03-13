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
    func getNotes(tag:String) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes:[Note] = try self.noteDao.query(tagId: tag)
                // 获取所有note的tags
                let noteTags = try self.tagDao.queryByTag(tagId: tag)
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
    
    func getNotes(status:NoteStatus = .normal) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
           self.executeTask(observable: observer) { () -> [NoteInfo] in
               let notes:[Note] = try self.noteDao.query(status: status)
               // 获取所有note的tags
               let noteTags = try self.tagDao.queryByTag(status: status)
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
                
    
    func getNotes(keyword:String) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes:[Note] = try self.noteDao.query(keyword: keyword)
                // 获取所有note的tags
                let noteTags = try self.tagDao.queryByKeyword(keyword)
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
                for tag in noteInfo.tags {
                    try self.noteTagDao.insert(NoteTag(noteId: noteInfo.id, tagId: tag.id))
                }
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
    
    func updateNoteStatus(_ note:Note,status:NoteStatus) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                var newNote = note
                newNote.status = status
                newNote.updatedAt = Date()
                try self.noteDao.updateStatus(status, noteId: note.id,updatedAt: newNote.updatedAt)
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func removeTrashedNotes() -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.noteDao.removeTrashedNotes()
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
    
    func updateNoteContentAndTags(_ noteInfo:NoteInfo,newContent:String,tagTitles:[String]) -> Observable<NoteInfo> {
        return Observable<NoteInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> NoteInfo in
                
                // 更新tag
                var newTags:[Tag] = try self.handleTags(note: noteInfo.note, tagTitles: tagTitles)
                
                var newNote = noteInfo.note
                newNote.content  = newContent
                newNote.updatedAt = Date()
                
                
                var newNoteInfo = noteInfo
                newNoteInfo.tags = newTags
                newNoteInfo.note  = newNote
                
                try self.noteDao.updateContent(newContent, noteId: newNote.id,updatedAt: newNote.updatedAt)
                return newNoteInfo
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    private func handleTags(note:Note,tagTitles:[String]) throws  -> [Tag]  {
        try self.noteTagDao.delete(noteId: note.id)
        
        if tagTitles.isEmpty { return [] }
        
         let date = Date()
            
        
        let tags = try self.tagDao.queryByTitles(tagTitles)
        let dict = Dictionary(uniqueKeysWithValues: tags.map{ ($0.title, $0) })
        
        var noteTags:[Tag] = []
        
        for tagTitle in tagTitles {
            var tag:Tag
            if let t = dict[tagTitle] {
                tag = t
            }else  {
                let newTag = Tag(title: tagTitle, createdAt: date, updatedAt: date)
                try self.tagDao.insert(newTag)
                tag  = newTag
            }
            noteTags.append(tag)
            try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
        }
        return noteTags
//        var tagTitles:[String] = []
//        for title in sortedTitles {
//            //新增 parent tag
//            let parentTitles = title.components(separatedBy: "/").dropLast()
//            var pTitle = ""
//            for (index,title) in parentTitles.enumerated() {
//
//                if index > 0 { pTitle += "/" }
//                pTitle += title
//                tagTitles.append(pTitle)
////                        let tag = try self.insertTag(tagTitle: pTitle, date: date, noteId: note.id)
////                        newTags.append(tag)
//            }
////                    let tag = try self.insertTag(tagTitle: title, date: date, noteId: note.id)
////                    newTags.append(tag)
//            tagTitles.append(title)
//        }
    }
    
    private func insertTag(tagTitle:String,date:Date,noteId:String) throws -> Tag {
        var tag:Tag
        if let existedTag = try tagDao.queryByTitle(title: tagTitle) {
            tag = existedTag
        }else {
            tag = Tag(title: tagTitle,createdAt: date,updatedAt: date)
            _ = try self.tagDao.insert(tag)
        }
        try self.noteTagDao.insert(NoteTag(noteId: noteId, tagId: tag.id))
        return tag
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
    
    func updateTag(tag:Tag) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.tagDao.update(tag)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
   func deleteNotesTag(tag:Tag) -> Observable<Void>  {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                var notes:[Note] = try self.noteDao.query(tagId: tag.id)
                let updatedAt = Date()
                
                // 替换所有 notes
                self.replaceNoteInsideTagTitles(oldTitle:tag.title, newTagTitle: "", updatedAt: updatedAt, notes: &notes)
                
                for note in notes {
                    let tagTitles = MDEditorViewController.extractTags(text:note.content)
                    try self.noteTagDao.delete(noteId: note.id)
                    // 更新 note content
                    try self.noteDao.updateContent(note.content, noteId: note.id, updatedAt: updatedAt)
                    for tagTitle in tagTitles {
                        var tag:Tag!
                        if let existedTag = try self.tagDao.queryByTitle(title: tagTitle) { // 已存在,更新
                            tag = existedTag
                            tag.updatedAt = updatedAt
                            try self.tagDao.update(tag)
                        }else {
                            let newTag = Tag(title: tagTitle, createdAt: updatedAt, updatedAt: updatedAt)
                            try self.tagDao.insert(newTag)
                            tag = newTag
                        }
                        try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
                    }
                }
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
   }
    
   // 更新所有note的tag，并返回新的tag
   func updateNotesTag(tag:Tag,newTagTitle:String) -> Observable<Tag?>  {
        return Observable<Tag?>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Tag? in
                var newTag:Tag?
                var notes:[Note] = try self.noteDao.query(tagId: tag.id)
                let updatedAt = Date()
                
                // 替换笔记内容
                self.replaceNoteInsideTagTitles(oldTitle:tag.title, newTagTitle: newTagTitle, updatedAt: updatedAt, notes: &notes)
                
//                let newTagTitles = MDEditorViewController.extractTags(text:newTagTitle)
                
                for note in notes {
                    let tagTitles = MDEditorViewController.extractTags(text:note.content)
                    try self.noteTagDao.delete(noteId: note.id)
                    // 更新 note content
                    try self.noteDao.updateContent(note.content, noteId: note.id, updatedAt: updatedAt)
                    for tagTitle in tagTitles {
                        var tag:Tag!
                        if let existedTag = try self.tagDao.queryByTitle(title: tagTitle) { // 已存在,更新
                            tag = existedTag
                            tag.updatedAt = updatedAt
                            try self.tagDao.update(tag)
                        }else {
                            let newTag = Tag(title: tagTitle, createdAt: updatedAt, updatedAt: updatedAt)
                            try self.tagDao.insert(newTag)
                            tag = newTag
                        }
                        try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
                        if tagTitle == newTagTitle {
                            newTag = tag
                        }
//                        if newTagTitles.contains(tagTitle) {
//                            TagExpandCache.shared.set(key: tag.id, value: tag.id)
//                        }
                    }
                }
                
                return newTag
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
   }
    
    
    // 更新 note 中的 tag
    private func replaceNoteInsideTagTitles(oldTitle:String,newTagTitle:String,updatedAt:Date, notes:inout [Note]){
        let pattern = #"#\#(oldTitle)#?"#
        let replace = self.generateReplaceTagTitle(title: newTagTitle)
        for (i,note) in notes.enumerated() {
            let content = note.content
            let newContent = content.replacingOccurrences(of: pattern, with: replace, options: .regularExpression)
            if content != newContent {
                print(newContent)
                var newNote = note
                newNote.updatedAt = updatedAt
                newNote.content = newContent
                notes[i] = newNote
            }
        }
    }
    
    private func generateReplaceTagTitle(title:String) -> String {
        if title.isEmpty {// 删除
            return ""
        }
        
        if title.contains(" ") {
            return "#\(title)#$2"
        }
        
        return "#\(title)$2"
    }
}
