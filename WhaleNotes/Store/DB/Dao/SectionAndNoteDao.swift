//
//  SectionNotesDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

fileprivate enum Field_SectionAndNote{
    static let id = Expression<String>("id")
    static let sectionId = Expression<String>("section_id")
    static let noteId = Expression<String>("note_id")
    static let sort = Expression<Double>("sort")
}

class SectionAndNoteDao {
    
    private var table: Table!
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        table = self.createTable()
    }
    
    func insert( _ sa:SectionAndNote) throws -> Int64 {
        let insertSection = self.generateSectionInsert(sa: sa,conflict: .ignore)
        let rowId = try db.run(insertSection)
        return rowId
    }
    
    func update(_ sa:SectionAndNote) throws -> Bool {
        let insertSection = self.generateSectionInsert(sa: sa,conflict: .ignore)
        let rows = try db.run(insertSection)
        return rows > 0
    }
    
    func queryBy(noteId: String,sectionId:String) throws -> SectionAndNote? {
        let query = table.filter(Field_SectionAndNote.noteId  == noteId && Field_SectionAndNote.sectionId == sectionId)
        let rows = try db.prepare(query)
        for row in rows {
            return generateSectionAndNote(row: row)
        }
        return nil
    }
    func isExists(noteId: String,boardId:String) throws -> Bool {
        
        let stmt = try db.prepare("select count(*) from section_note inner join section on (section.id = section_note.section_id and section.board_id = ? and section_note.note_id = ? )")
        let count = try stmt.scalar(boardId,noteId)  as! Int64
        return count > 0
   }
    
    func queryFirst(sectionId:String) throws -> SectionAndNote? {
        let query = table.filter(Field_SectionAndNote.sectionId == sectionId).order(Field_SectionAndNote.sort.asc).limit(1)
        let rows = try db.prepare(query)
        for row in rows {
            return generateSectionAndNote(row: row)
        }
        return nil
    }
    
    func delete(id: String)  throws -> Bool {
        let sectionData = table.filter(Field_SectionAndNote.id == id)
        let rows = try db.run(sectionData.delete())
        return rows > 0
    }
    
    func deleteByNoteId(_ noteId:String) throws -> Bool{
        let sectionData = table.filter(Field_SectionAndNote.noteId == noteId)
        let rows = try db.run(sectionData.delete())
        return rows > 0
    }
    
    func deleteByNoteIds(_ noteIds:[String]) throws -> Bool{
        let sectionData = table.filter(noteIds.contains(Field_SectionAndNote.noteId))
        let rows = try db.run(sectionData.delete())
        return rows == noteIds.count
    }
    
    func deleteByBoardId(_ boardId:String,noteId:String) throws -> Bool{
        let stmt = try db.prepare("""
            delete from section_note where id in (
                select section_note.id from section_note
                inner join section on (section.id = section_note.section_id and section.board_id = ?)
            ) and section_note.note_id = ?
         """)
        try stmt.run(boardId,noteId)
        let rows = db.changes
        return rows > 0
    }
    

        func deleteByBoardId(_ boardId:String) throws -> Int{
            let stmt =  try db.prepare("""
                delete from section_note where id in (
                    select section_note.id from section_note
                    inner join section on (section.id = section_note.section_id and section.board_id = ?)
                )
        """)
            try stmt.run(boardId)
            let rows = db.changes
            return rows
        }
}


extension SectionAndNoteDao {
    fileprivate func createTable() -> Table {
        let table = Table("section_note")
        
        do {
            try! db.run(
                table.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_SectionAndNote.id)
                    builder.column(Field_SectionAndNote.sectionId)
                    builder.column(Field_SectionAndNote.noteId)
                    builder.column(Field_SectionAndNote.sort)
                })
            )
        }
        return table
    }
    
    
    
    
    fileprivate func generateSectionInsert(sa: SectionAndNote,conflict:OnConflict = OnConflict.fail) -> Insert {
        
            return table.insert(or: conflict,
                                Field_SectionAndNote.id <- sa.id,
                                Field_SectionAndNote.sectionId <- sa.sectionId,
                                Field_SectionAndNote.noteId <- sa.noteId,
                                Field_SectionAndNote.sort <- sa.sort
            )
    }
    
    fileprivate func generateSectionAndNote(row: Row) -> SectionAndNote {
        let sa = SectionAndNote(id: row[Field_SectionAndNote.id], sectionId:  row[Field_SectionAndNote.sectionId], noteId:  row[Field_SectionAndNote.noteId], sort:  row[Field_SectionAndNote.sort])
        return sa
    }
}
