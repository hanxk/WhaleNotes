//
//  NotesDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import Foundation
import SQLite

enum Field_Notes{
    static let id = Expression<Int64>("id")
    static let createdAt = Expression<Date>("created_at")
    static let updatedAt = Expression<Date>("updated_at")
}

class NotesDao {
    
    private var table: Table!
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        table = self.createTable()
    }
    
    func insert( _ note:Note) throws -> Int64 {
        let insertNote = self.generateNoteInsert(note: note,conflict: .ignore)
        let rowId = try db.run(insertNote)
        return rowId
    }
    
    func delete(id: Int64)  throws -> Bool {
        let note = table.filter(Field_Notes.id == id)
        let rows = try db.run(note.delete())
        return rows > 0
    }
    
    func updateUpdatedAt(id:Int64) throws -> Bool {
          let note = table.filter(Field_Notes.id == id)
          let rows = try db.run(note.update(Field_Notes.updatedAt <- Date()))
          return rows == 1
   }
    
    
    
    func queryAll() throws ->[Note] {
        let rows = try db
            .prepare(table.order(Field_Notes.updatedAt.desc))
        var notes:[Note] = []
        for row in rows {
            let bote = generateNote(row: row)
            notes.append(bote)
        }
        return notes
    }
    
}


extension NotesDao {
    fileprivate func createTable() -> Table {
        let tableBlock = Table("notes")
        
        do {
            try! db.run(
                tableBlock.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Notes.id,primaryKey: .autoincrement)
                    builder.column(Field_Notes.createdAt)
                    builder.column(Field_Notes.updatedAt)
                })
            )
        }
        return tableBlock
    }
    
    
    
    
    fileprivate func generateNoteInsert(note: Note,conflict:OnConflict = OnConflict.fail) -> Insert {
        
        if note.id > 0 {
            return table.insert(or: conflict,
                                Field_Notes.id <- note.id,
                                Field_Notes.createdAt <- note.createdAt,
                                Field_Notes.updatedAt <- note.updatedAt
            )
        }
        return table.insert(or: conflict,
                            Field_Notes.createdAt <- note.createdAt,
                            Field_Notes.updatedAt <- note.updatedAt
        )
        
    }
    
    fileprivate func generateNote(row: Row) -> Note {
        let note = Note(id: row[Field_Blocks.id], createdAt: row[Field_Blocks.createdAt], updatedAt: row[Field_Blocks.createdAt])
        return note
    }
}
