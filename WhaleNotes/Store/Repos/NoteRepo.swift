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
    
   func updateNotesTag(tag:Tag,newTitle:String) -> Observable<Tag>  {
    
        return Observable<Tag>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Tag in
                var newTag:Tag!
                var notes:[Note] = try self.noteDao.query(tagId: tag.id)
                let updatedAt = Date()
                self.replaceNoteInsideTagTitles(oldTitle:tag.title, newTagTitle: newTitle, updatedAt: updatedAt, notes: &notes)
                
                for note in notes {
                    let tagTitles = MDEditorViewController.extractTags(text:note.content)
                    try self.noteTagDao.delete(noteId: note.id)
                    // 更新 note content
                    try self.noteDao.updateContent(note.content, noteId: note.id, updatedAt: updatedAt)
                    for tagTitle in tagTitles {
                        var tag:Tag!
                        if let existedTag = try self.tagDao.queryByTitle(title: tagTitle) { // 已存在
                            tag = existedTag
                        }else {
                            let newTag = Tag(title: tagTitle, createdAt: updatedAt, updatedAt: updatedAt)
                            try self.tagDao.insert(newTag)
                            tag = newTag
                        }
                        try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
                        if tagTitle == newTitle {
                            newTag = tag
                        }
                    }
                }
                
                return newTag
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
   }
    
    /**
            更新和tag相关的所有note
     */
    func updateNotesTag(tag:Tag,tagTitles:[String]) -> Observable<Tag>  {
        return Observable<Tag>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Tag in
                
                let updatedAt = Date()
                var notes:[Note] = try self.noteDao.query(tagId: tag.id)
                
                
                let newTagTitle = tagTitles[tagTitles.count-1]
                
                
                func updateTag(tag:Tag,newTagTitle:String) throws -> Tag  {
                    var newTag = tag
                    newTag.title = newTagTitle
                    newTag.updatedAt = updatedAt
                    try self.tagDao.update(newTag)
                    return newTag
                }
                
                var newTag:Tag!
                // 存储需要替换掉的tag
                var delAndUpdateTags:[(Tag,Tag)] = []
                
                for tagTitle in tagTitles {
                    if let existedTag = try self.tagDao.queryByTitle(title: newTagTitle) { // 已存在
                        delAndUpdateTags.append((tag,existedTag))
                    }
                }
                
                
                
                //1. 更新当前 tag 并替换 notes 中的tag
                if let existedTag = try self.tagDao.queryByTitle(title: newTagTitle) { // 已存在
                    newTag = existedTag
                    delAndUpdateTags.append((tag,existedTag))
                }else {
                    newTag = try updateTag(tag: tag, newTagTitle: newTagTitle)
                    
                }
                // 更新 note content
                self.replaceNoteInsideTagTitles(oldTitle:tag.title, newTagTitle: newTagTitle, updatedAt: updatedAt, notes: &notes)
                
                //2.更新child tag
//                let childTags = try self.tagDao.queryChildTags(parentTitle: tag.title).filter({
//                    $0.title != newTagTitle
//                })
//                for childTag in childTags {
//                    let newChildTitle = childTag.title.replacingOccurrences(of: tag.title, with: newTagTitle)
//                    if let existedTag = try self.tagDao.queryByTitle(title: newTagTitle) { // 已存在
//                        delAndUpdateTags.append((childTag,existedTag))
//                    }else {
//                        // 更新  child tag
//                        _ = try updateTag(tag: childTag, newTagTitle: newChildTitle)
//                    }
//                    // 替换 notes 中的tag
//                    self.replaceNoteInsideTagTitles(oldTitle:childTag.title, newTagTitle: newChildTitle, updatedAt: updatedAt, notes: &notes)
//                }
                
                
                //3. 新增 tag
                var newTags:[Tag] = []
                if tagTitles.count > 1 {
                    let existTags = try self.tagDao.queryByTitles(tagTitles)
                    for tagTitle in tagTitles.dropLast(){
                        let isExists = existTags.contains(where: {$0.title == tagTitle})
                        if isExists { continue }
                        let tag = Tag(title: tagTitle, createdAt: updatedAt, updatedAt: updatedAt)
                        newTags.append(tag)
                        try self.tagDao.insert(tag)
                    }
                }
                
                // 统一更新notes
                for note in notes {
                    if note.updatedAt == updatedAt {
                        try self.noteDao.updateContent(note.content, noteId: note.id, updatedAt: updatedAt)
                        //4 和新的tag建立关联
                        for t in newTags {
                            try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: t.id))
                        }
                        
//                        if newTag.id != tag.id { // 当前 tag 下的 tag 已被替换
//                            try self.noteTagDao.delete(noteId: note.id, tagId:  tag.id)
//                            try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: newTag.id))
//                        }
                        
                        for (delTag,updateTag) in delAndUpdateTags  {
                            try self.noteTagDao.delete(noteId: note.id, tagId:  delTag.id)
                            try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: updateTag.id))
                        }
                    }
                }
                
                return newTag
                
                
                
                
                //有可能需要新增 tag
//                var newTags:[Tag] = []
//                if tagTitles.count > 1 {
//                    let existTags = try self.tagDao.queryByTitles(tagTitles)
//                    for tagTitle in tagTitles{
//                        let isExists = existTags.contains(where: {$0.title == tagTitle})
//                        if isExists { continue }
//                        let tag = Tag(title: tagTitle, createdAt: updatedAt, updatedAt: updatedAt)
//                        newTags.append(tag)
//                    }
//                }
//                for tag in newTags {
//                    try self.tagDao.insert(tag)
//                }
                
                
                // 更新 child tag
//                let childTags = try self.tagDao.queryChildTags(parentTitle: tag.title)
//                for childTag in childTags {
//                    let newChildTitle = childTag.title.replacingOccurrences(of: tag.title, with: newTagTitle)
//                    _ = try self.updateTagInsideNote(tag: childTag, newTagTitle: newChildTitle, updatedAt: updatedAt, notes: &notes)
//                }
//
//                // 更新当前 tag
//                let mewTag = try self.updateTagInsideNote(tag: tag, newTagTitle: newTagTitle, updatedAt: updatedAt, notes: &notes)
                
                
                
                
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    // 更新 note 中的 tag
    private func replaceNoteInsideTagTitles(oldTitle:String,newTagTitle:String,updatedAt:Date, notes:inout [Note]) {
        let pattern = "\\B#(\(oldTitle))(\\/[^#\\/\\s]*)*(?=\\s|$)"
        for (i,note) in notes.enumerated() {
            let content = note.content
            let newContent = content.replacingOccurrences(of: pattern, with: "#\(newTagTitle)$2", options: .regularExpression)
            if content != newContent {
                var newNote = note
                newNote.updatedAt = updatedAt
                newNote.content = newContent
                notes[i] = newNote
            }
        }
        //提炼出新的 tags
        
    }
}
