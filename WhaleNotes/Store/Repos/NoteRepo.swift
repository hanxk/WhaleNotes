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
    func getNotes(tag:String,offset:Int = 0,pageSize:Int = PAGESIZE) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes:[Note] = try self.noteDao.queryPage(tagId: tag,offset: offset,pageSize: pageSize)
                if notes.isEmpty {
                    return []
                }
                let noteIds = notes.map { $0.id }
                 // 获取所有note的tags
                let noteTags = try self.tagDao.queryByTag(noteIds: noteIds)
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
    
    func getNotes(status:NoteStatus = .normal,offset:Int = 0) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes:[Note] = try self.noteDao.query(status: status,offset: offset)
                if notes.isEmpty {
                    return []
                }
                let noteIds = notes.map { $0.id }
                // 获取所有note的tags
                let noteTags = try self.tagDao.queryByTag(noteIds: noteIds)
                
                // 获取图片
                let noteFilesMap = try self.noteFileDao.queryByTag(noteIds: noteIds)
                
                var noteInfos:[NoteInfo] = []
                for note in notes {
                    let tags = noteTags.filter{$0.0 == note.id}.map { $0.1 }
                    let noteFiles:[NoteFile] = noteFilesMap[note.id] ?? []
                    noteInfos.append(NoteInfo(note: note, files:noteFiles,tags: tags))
                }
                return noteInfos
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func getNotesAndTags(fromDate:Date) -> Observable<([Note],[Tag])> {
        return Observable<([Note],[Tag])>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> ([Note],[Tag]) in
                let notes:[Note] = try self.noteDao.queryFromDate(fromDate)
                let tags:[Tag] = try self.tagDao.queryFromDate(fromDate)
                return (notes,tags)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func getNotes(keyword:String,offset:Int) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes:[Note] = try self.noteDao.query(keyword: keyword,offset: offset)
                if notes.isEmpty {
                    return []
                }
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
    
    func createNote(_ note:Note) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                try self.noteDao.insert(note)
                return note
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    func createNotesAndTags(notes:[Note],tags:[Tag]) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                for tag in tags {
                    try self.tagDao.insert(tag)
                }
                let localNotes = try self.noteDao.queryByIDs(notes.map{ $0.id })
                for note in notes {
                    try self.noteDao.insert(note)
                    
                    if let oldNote = localNotes.first(where: {$0.id == note.id}) {
                        if  oldNote.content == note.content {
                            // content 没有发生改变
                            continue
                        }
                        try self.noteTagDao.delete(noteId: note.id)
                    }
                    // 关联关系
                    let tags = try self.extractTagsFromNote(note)
                    for tag  in tags {
                        try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
                    }
                }
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    private func extractTagsFromNote( _ note:Note) throws -> [Tag] {
        let tagTitles = MDEditorViewController.extractTags(text: note.content)
        
        var tags = try self.tagDao.queryByTitles(tagTitles)
        
        // 本地没有，需要重新创建
        let newTagTitles = tagTitles.filter({ tagTitle in
            tags.contains(where: {$0.title == tagTitle})
        })
        
        let date = Date()
        try newTagTitles.forEach {
            let newTag = Tag(title: $0, createdAt: date, updatedAt: date)
            try self.tagDao.insert(newTag)
            tags.append(newTag)
        }
        return tags
    }
    
    func updateNote(_ note:Note) -> Observable<Note> {
        return Observable<Note>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Note in
                try self.noteDao.update(note)
                return note
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
    
    func updateNoteAndTags(_ noteInfo:NoteInfo,note:Note,tagTitles:[String]) -> Observable<NoteInfo> {
        return Observable<NoteInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> NoteInfo in
                
                // 更新tag
                let newTags:[Tag] = try self.handleTags(noteId:noteInfo.id, tagTitles: tagTitles)
                
                var newNoteInfo = noteInfo
                newNoteInfo.note  = note
                newNoteInfo.tags = newTags
                
                try self.noteDao.update(note)
                return newNoteInfo
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    private func handleTags(noteId:String,tagTitles:[String]) throws  -> [Tag]  {
        try self.noteTagDao.delete(noteId: noteId)
        
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
            try self.noteTagDao.insert(NoteTag(noteId: noteId, tagId: tag.id))
        }
        return noteTags
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
                try self.noteDao.mark2Del(noteInfo.id)
                try self.noteTagDao.delete(noteId: noteInfo.id)
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
    
    // 删除无用的tag
    func markUnusedTags2Deled() -> Observable<Void>  {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.tagDao.markUnusedTags2Deled()
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
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
    
    
    func delteNotes(tag:Tag) -> Observable<Void>  {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                var notes:[Note] = try self.noteDao.query(tagId: tag.id)
                let updatedAt = Date()
                
                // 替换所有 notes
                self.replaceNoteTags(oldTagTitle: tag.title, newTagTitle: "", updatedAt: updatedAt, notes: &notes)
                
                //删除当前tag及子tag
                try self.tagDao.updateTags2Del(tagTitle: tag.title)
                

                for note in notes {
                    let tagTitles = MDEditorViewController.extractTags(text:note.content)
                    try self.noteTagDao.delete(noteId: note.id)
                    // 更新 note content
                    try self.noteDao.updateContent(note.content, noteId: note.id, updatedAt: updatedAt)
                    for tagTitle in tagTitles {
                        var tag:Tag!
                        if let existedTag = try self.tagDao.queryByTitle(title: tagTitle) { // 已存在,更新
                            tag = existedTag
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
                var visibleTag:Tag?
                var notes:[Note] = try self.noteDao.query(tagId: tag.id)
                let updatedAt = Date()
                
                // 替换笔记内容
                self.replaceNoteTags(oldTagTitle: tag.title, newTagTitle: newTagTitle, updatedAt: updatedAt, notes: &notes)
                
                func generateAllTagTitles(tagTitle:String) -> [String] {
                    let tagTitles = newTagTitle.components(separatedBy: "/").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }.filter{$0.isNotEmpty}
                    var newTagTitles:[String] = []
                    var p = ""
                    for (index,tagTitle) in tagTitles.enumerated() {
                        p += tagTitle
                        newTagTitles.append(p)
                        if index != tagTitles.count - 1 {
                            p += "/"
                        }
                    }
                    return newTagTitles
                }
                
                let newTagTitles = generateAllTagTitles(tagTitle: newTagTitle)
                let visibleTagTitle = newTagTitles[newTagTitles.count-1]
                
                for note in notes {
                    let tagTitles = MDEditorViewController.extractTags(text:note.content)
                    try self.noteTagDao.delete(noteId: note.id)
                    // 更新 note content
                    try self.noteDao.updateContent(note.content, noteId: note.id, updatedAt: updatedAt)
                    // 查询title
                    let existsTags = try self.tagDao.queryByTitles(tagTitles)
                    for tagTitle in tagTitles {
                        var tag:Tag!
                        if let existedTag = existsTags.first(where: {$0.title == tagTitle}) { // 已存在,更新
                            tag = existedTag
                            tag.updatedAt = updatedAt
                            try self.tagDao.update(tag)
                        }else {
                            let newTag = Tag(title: tagTitle, createdAt: updatedAt, updatedAt: updatedAt)
                            try self.tagDao.insert(newTag)
                            tag = newTag
                        }
                        try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
                        if newTagTitles.contains(tagTitle) {//全部展开
                            TagExpandCache.shared.set(key: tag.id, value: tag.id)
                        }
                        if visibleTagTitle == tag.title {
                            visibleTag = tag
                        }
                    }
                }
                
                return visibleTag
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
}

//MARK: 处理图片
extension NoteRepo {
    
    
    func saveImage(fileInfo:FileInfo,noteInfo:NoteInfo) -> Observable<NoteInfo?> {
        return Observable<NoteInfo?>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> NoteInfo? in
                //1.  缓存图片到本地
                let isSuccess = try LocalFileUtil.shared.saveFileInfo(fileInfo: fileInfo)
                if !isSuccess {
                    return nil
                }
                let date = Date()
                
                var newNoteInfo = noteInfo
                newNoteInfo.updatedAt = date
                
                try self.noteDao.updateUpdatedAt(id: noteInfo.id, updatedAt: date)
                
                //2. 生成一个 notefile 添加的数据库中
                let noteFile = NoteFile(id:fileInfo.fileId,fileName: fileInfo.fileName, noteId: noteInfo.id, width: Double(fileInfo.image.width), height: Double(fileInfo.image.height), fileSize: fileInfo.image.fileSize, sort: 0, createdAt: date, updatedAt:date)
                try self.noteFileDao.insert(noteFile)
                
                newNoteInfo.files.append(noteFile)
                return newNoteInfo
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}


//MARK: replace tag title
extension NoteRepo {
    
    
    private func replaceNoteTags(oldTagTitle:String,newTagTitle:String,updatedAt:Date,notes:inout [Note]) {
        var replace = ""
        var pattern = ""
        
        if newTagTitle.isEmpty {
            if let splitIndex = oldTagTitle.lastIndex(of: "/") { // old: #a/b/c  remove: #a/b/c  => #a/b
                replace = "#"+oldTagTitle.subString(to: splitIndex)
            }
            pattern = #"#\#(oldTagTitle)[^#\s]*#?"#
        }else {
//            pattern = #"#\#(oldTagTitle)([^#\s]*)(?=#?)"#
            pattern = #"(?<=\s|^)#\#(oldTagTitle)(\/[^\s]+)*(?:#|(?=\s|$))"#
            replace = "#\(newTagTitle)$1"
        }
        self.replaceNoteContent(pattern: pattern, replace: replace, updatedAt: updatedAt, notes: &notes)
        
    }
    
    private func removeNoteInsideTagTitles(tagTitle:String,updatedAt:Date, notes:inout [Note]){
        var replace = ""
        if let splitIndex = tagTitle.lastIndex(of: "/") { // old: #a/b/c  remove: #a/b/c  => #a/b
            replace = "#"+tagTitle.subString(to: splitIndex)
        }
        let pattern = #"#\#(tagTitle)[^#\s]*#?"#
        self.replaceNoteContent(pattern: pattern, replace: replace, updatedAt: updatedAt, notes: &notes)
    }
    
//  // 更新 note 中的 tag
    private func replaceNoteInsideTagTitles(oldTitle:String,newTagTitle:String,includeChild:Bool=false,updatedAt:Date, notes:inout [Note]){
        let pattern = #"(?<=\s|^)#(\#(oldTitle)(?:(?: *[^#\s]+)*#)?)(?=[\s\n])"#
        let replace = "#\(newTagTitle)$1"
        self.replaceNoteContent(pattern: pattern, replace: replace, updatedAt: updatedAt, notes: &notes)
    }
    
    private func replaceNoteContent(pattern:String,replace:String,updatedAt:Date,notes:inout [Note]) {
        for (i,note) in notes.enumerated() {
            let content = note.content
            let newContent = content.replacingOccurrences(of: pattern, with: replace, options: .regularExpression)
            if content != newContent {
                logi("新的 content: \(newContent)")
                var newNote = note
                newNote.updatedAt = updatedAt
                newNote.content = newContent
                notes[i] = newNote
            }
        }
    }
    
    
    
    private func generateReplaceTagTitle(oldTagTitle:String,newTagTitle:String) -> String {
        var replace = ""
        if newTagTitle.isEmpty { // 删除
            if let splitIndex = oldTagTitle.lastIndex(of: "/") {
                replace = "#"+oldTagTitle.subString(to: splitIndex)
            }
        }else {
            replace = "#\(newTagTitle)$1"
        }
        return replace
    }
}
