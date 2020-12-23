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
    
    func query(tagId:String) throws -> [Note]  {
        let selectSQL = "select * from note where id in (select note_id from note_tag where tag_id = ?) order by created_at desc"
        let rows = try db.query(selectSQL,args: tagId)
        return extract(rows: rows)
    }
    
    func query() throws -> [Note]  {
        let selectSQL = "select * from note  order by created_at desc"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    
    func query(id:String) throws -> Note?  {
        let selectSQL = "select * from note where id = ?"
        let rows = try db.query(selectSQL,args:id)
        if rows.count == 0 { return nil}
        return extract(row: rows[0])
    }
    
    func update( _ note:Note) throws {
        let updateSQL = "update note set title = ?,content = ?,updated_at=strftime('%s', 'now') where id = ?"
        try db.execute(updateSQL, args: note.title,note.content,note.id)
    }
    
    func delete( _ id:String) throws {
        let delSQL = "delete from note where id = ?"
        try db.execute(delSQL, args: id)
    }
    
    func updateUpdatedAt(id:String,updatedAt:Date) throws {
        let updateSQL = "update note set updated_at=? where id = ?"
        try db.execute(updateSQL, args: updatedAt.timeIntervalSince1970,id)
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
    
    fileprivate func extract(row: Row) -> Note {
        let note = extractNote(from: row)
        return note
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
