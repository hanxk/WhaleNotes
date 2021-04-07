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
    
    func queryChanged() throws -> [Note] {
        return try noteDao.queryChanged()
    }
    
    func clearChanged() throws {
        try self.db.transaction {
            try noteDao.resetUpdateChangedNotes()
        }
    }
    
    func deleteNotesForever(noteIDs:[String]) throws {
        try self.db.transaction {
            for noteID in noteIDs {
                try noteDao.delete(noteID, softDel: false)
            }
        }
    }
    
    func save(notes:[Note],tags:[Tag]) throws {
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
}