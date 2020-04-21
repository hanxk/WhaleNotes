//
//  NotesDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite


enum Field_Note {
    static let id = Expression<Int64>("id")
    static let createAt = Expression<Date>("create_at")
    static let updateAt = Expression<Date>("update_at")
}

class NotesDao {
    
    static let shared = NotesDao()
    private var tableNote: Table?
    fileprivate var db: Connection {
        return SQLiteManager.manager.getDB()
    }
    
    init() {
        _ = _getTableNote()
    }
    
    func insert( _ note:Note) throws -> Int64 {
        let insertNote = self._generateNoteInsert(note: note,conflict: .ignore)
        let rowId = try db.run(insertNote)
        return rowId
    }
    
    func update( _ note:Note) throws -> Int64 {
        let insertNote = self._generateNoteInsert(note: note,conflict: .replace)
        let rowId = try SQLiteManager.manager.getDB().run(insertNote)
        return rowId
    }
    
    func deleteForever(id:Int64) throws -> Int {
        let rowEffects = try db.run(_getTableNote().filter(Field_Note.id == id).delete())
        return rowEffects
    }
    
    func getNotes(tagId: Int64,order: Int) throws -> [Note] {
        let noteRows = try db
            .prepare(_getTableNote())
        //        .filter(Field_Note.bookId == bookId).order(Field_Note.updateAt.desc))
        var notes:[Note] = []
        for row in noteRows {
            let note = _generateNote(row: row)
            notes.append(note)
        }
        return notes
    }
    
}


extension NotesDao {
    
    func createTableIfNotExists() {
        _ = _getTableNote()
    }
    
    fileprivate func _getTableNote() -> Table {
        
        if tableNote == nil {
            
            tableNote = Table("note")
            
            do {
                try! SQLiteManager.manager.getDB().run(
                    tableNote!.create(ifNotExists: true, block: { (builder) in
                        builder.column(Field_Note.id,primaryKey: .autoincrement)
                        builder.column(Field_Note.updateAt)
                        builder.column(Field_Note.createAt)
                    })
                )
            }
            
        }
        return tableNote!
    }
    
    func _generateNoteInsert(note: Note,conflict:OnConflict = OnConflict.ignore) -> Insert {
        
        if note.id > 0 {
            return  _getTableNote().insert(or: conflict,
                                           Field_Note.id <- note.id,
                                           Field_Note.updateAt <- note.updateAt,
                                           Field_Note.createAt <- note.createAt
            )
        }
        return _getTableNote().insert(or: conflict,
                                      Field_Note.updateAt <- note.updateAt,
                                      Field_Note.createAt <- note.createAt
        )
        
    }
    
    
    func _generateNote(row: Row) -> Note {
        let note = Note(id: row[Field_Note.id], blocks: [], createAt:  row[Field_Note.createAt], updateAt: row[Field_Note.updateAt])
        return note
    }
    
}
