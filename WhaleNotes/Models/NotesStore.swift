//
//  NotesModel.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/4/5.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation

class NotesStore {
    static var shared = NotesStore()
    private var noteDao:NoteDao {
        return NoteRepo.shared.noteDao
    }
    private var tagDao:TagDao {
        return NoteRepo.shared.tagDao
    }
    private var noteTagDao:NoteTagDao {
        return NoteRepo.shared.noteTagDao
    }
    private var db:SQLiteDatabase {
        return NoteRepo.shared.db
    }
    private init() {
        
    }
    
    func queryChangedNotes(date:Date) throws -> [Note] {
        let notes = try noteDao.queryFromUpdatedDate(date: date)
        return notes
    }
    func queryChangedTags(date:Date) throws -> [Tag] {
        let tags = try tagDao.queryFromUpdatedDate(date: date)
        return tags
    }
    
    
    func deleteNotesForever(noteIDs:[String]) throws {
        try self.db.transaction {
            for noteID in noteIDs {
                try noteDao.delete(noteID, softDel: false)
            }
        }
    }
    
    func deleteTagsForever(tagIDs:[String]) throws {
        try self.db.transaction {
            for tagID in tagIDs {
                try noteDao.delete(tagID, softDel: false)
            }
        }
    }
    
    func save(notes:[Note],tags:[Tag]) throws {
        try self.db.transaction {
            
            let existsTags = try self.tagDao.queryByIDs(tags.map { $0.id })
            for tag in tags {
                if let existsTag = existsTags.first(where: {$0.id == tag.id}),existsTag.updatedAt >= tag.updatedAt {
                    // 本地是最新的
                    continue
                }
                try self.tagDao.insert(tag)
            }
            
            let localNotes = try self.noteDao.queryByIDs(notes.map{ $0.id })
            for note in notes {
                if let existsNote = localNotes.first(where: {$0.id == note.id}),existsNote.updatedAt >= note.updatedAt {
                    continue
                }
                // 更新 note
                try self.noteDao.insert(note)
                
                // 删除关联关系
                try self.noteTagDao.delete(noteId: note.id)
                // 重建关联关系
                let tags = try self.extractTagsFromNote(note)
                for tag  in tags {
                    try self.noteTagDao.insert(NoteTag(noteId: note.id, tagId: tag.id))
                }
            }
        }
    }
    
    private func extractTagsFromNote( _ note:Note) throws -> [Tag] {
        let tagTitles = MDEditorViewController.extractTags(text: note.content)
        
        var tags = try self.tagDao.queryByTitles(tagTitles)
        if tagTitles.count == tags.count { return tags}
        
        let notExistsTagTitles = tagTitles.filter {tagTitle in tags.contains(where: {$0.title != tagTitle}) }
        let date = Date()
        try notExistsTagTitles.forEach {
            let newTag = Tag(title: $0, createdAt: date, updatedAt: date)
            try self.tagDao.insert(newTag)
            tags.append(newTag)
        }
        return tags
    }
}


extension NotesStore {
    func queryDelTags() throws -> [Tag] {
        let tags = try tagDao.queryDelTags()
        return tags
    }
}
