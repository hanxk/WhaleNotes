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
        let insertSQL = "insert into note(id,title,content,created_at,updated_at) values(?,?,?,?,?)"
        try db.execute(insertSQL, args: note.id,note.title,note.content,note.createdAt.timeIntervalSince1970,note.updatedAt.timeIntervalSince1970)
    }
    
    func query() throws -> [Note]  {
        let selectSQL = "select * from note order by created_at desc"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func update( _ note:Note) throws {
        let updateSQL = "update note set title = ?,content = ?,updated_at=strftime('%s', 'now') where id = ?"
        try db.execute(updateSQL, args: note.title,note.content,note.id)
    }
    
    func delete( _ id:String) throws {
        let delSQL = "delete from note where id = ?"
        try db.execute(delSQL, args: id)
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
        let title = row["title"] as! String
        let content = row["content"] as! String
        let createdAt = Date(timeIntervalSince1970:  row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970:  row["updated_at"] as! Double)
        return  Note(id: id,title: title, content: content, createdAt: createdAt, updatedAt: updatedAt)
    }
}
