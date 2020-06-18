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
    static let id = Expression<Int64>("id")
    static let sectionId = Expression<Int64>("section_id")
    static let noteId = Expression<Int64>("note_id")
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
    
    func delete(id: Int64)  throws -> Bool {
        let sectionData = table.filter(Field_SectionAndNote.id == id)
        let rows = try db.run(sectionData.delete())
        return rows > 0
    }
    
    func delete(sectionId:Int64,noteId:Int64) throws -> Bool{
        let sectionData = table.filter(Field_SectionAndNote.sectionId == sectionId && Field_SectionAndNote.noteId == noteId)
        let rows = try db.run(sectionData.delete())
        return rows > 0
    }
}


extension SectionAndNoteDao {
    fileprivate func createTable() -> Table {
        let table = Table("section_note")
        
        do {
            try! db.run(
                table.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_SectionAndNote.id,primaryKey: .autoincrement)
                    builder.column(Field_SectionAndNote.sectionId)
                    builder.column(Field_SectionAndNote.noteId)
                    builder.column(Field_SectionAndNote.sort)
                })
            )
        }
        return table
    }
    
    
    
    
    fileprivate func generateSectionInsert(sa: SectionAndNote,conflict:OnConflict = OnConflict.fail) -> Insert {
        if sa.id > 0 {
            return table.insert(or: conflict,
                                Field_SectionAndNote.id <- sa.id,
                                Field_SectionAndNote.sectionId <- sa.sectionId,
                                Field_SectionAndNote.noteId <- sa.noteId,
                                Field_SectionAndNote.sort <- sa.sort
            )
        }
        return table.insert(or: conflict,
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
