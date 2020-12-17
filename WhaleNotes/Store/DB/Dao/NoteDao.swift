//
//  NoteDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
class NoteDao {
    
    private  var db: SQLiteDatabase!
    
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
    
}

extension NoteDao {
    func insert( _ note:Note) throws {
        let insertSQL = "insert into note(id,content) values(?,?)"
        try db.execute(insertSQL, args: note.id,note.content)
    }
    
    func query() throws -> [Note]  {
        let selectSQL = "select * from note order by created_at desc"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
}

extension NoteDao {
    
    fileprivate func extract(rows: [Row]) -> [Note] {
        var notes:[Note] = []
        for row in rows {
            notes.append(extractNote(from: row))
        }
        return notes
    }
    
    fileprivate func extract(row: Row) -> NoteInfo {
        let note = extractNote(from: row)
        return NoteInfo(note: note, tags: [])
    }
    
    fileprivate func extractNote(from row: Row) -> Note {
        let id = row["id"] as! String
        let content = row["content"] as! String
        let createdAt = row["created_at"] as! Date
        let updatedAt = row["updated_at"] as! Date
        return  Note(id: id, content: content, createdAt: createdAt, updatedAt: updatedAt)
    }
}
