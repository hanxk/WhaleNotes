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
        let insertSQL = "insert into note(id,title,content,status,created_at,updated_at) values(?,?,?,?,?,?)"
        try db.execute(insertSQL, args: note.id,note.title,note.content,note.status.rawValue,note.createdAt.timeIntervalSince1970,note.updatedAt.timeIntervalSince1970)
    }
    
    func query(tagId:String) throws -> [Note]  {
        let selectSQL = "select * from note where id in (select note_id from note_tag where tag_id = ?) order by created_at desc"
        let rows = try db.query(selectSQL,args: tagId)
        return extract(rows: rows)
    }
    
    func queryPage(tagId:String,offset:Int,pageSize:Int = PAGESIZE) throws -> [Note]  {
//        let offset = PAGESIZE * pageIndex
        let selectSQL = "select * from note where id in (select note_id from note_tag where tag_id = ?) order by created_at desc  LIMIT \(pageSize) OFFSET \(offset)"
        let rows = try db.query(selectSQL,args: tagId)
        return extract(rows: rows)
    }
    
    func query(status:NoteStatus = .normal,offset:Int) throws -> [Note]  {
//        let offset = PAGESIZE * pageIndex
        let selectSQL = "select * from note where status  = ? order by created_at desc LIMIT \(PAGESIZE) OFFSET \(offset)"
        let rows = try db.query(selectSQL,args: status.rawValue)
        return extract(rows: rows)
    }
    
    func query(keyword:String,offset:Int) throws -> [Note]  {
//        let offset = PAGESIZE * pageIndex
        let selectSQL = "select * from note where status != -1  AND (title  like '%\(keyword)%'  or content like '%\(keyword)%') order by created_at desc LIMIT \(PAGESIZE) OFFSET \(offset)"
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
        let updateSQL = "update note set title = ?,content = ?,status = ?,updated_at=strftime('%s', 'now') where id = ?"
        try db.execute(updateSQL, args: note.title,note.content,note.status,note.id)
    }
    
    func updateContent( _ content:String,noteId:String,updatedAt:Date) throws {
        let updateSQL = "update note set  content = ?,updated_at=? where id = ?"
        try db.execute(updateSQL, args: content,updatedAt.timeIntervalSince1970,noteId)
    }
    
    func updateTitle( _ title:String,noteId:String,updatedAt:Date) throws {
        let updateSQL = "update note set  title = ?,updated_at=? where id = ?"
        try db.execute(updateSQL, args: title,updatedAt.timeIntervalSince1970,noteId)
    }
    
    func updateStatus( _ status:NoteStatus,noteId:String,updatedAt:Date) throws {
        let updateSQL = "update note set status = ?,updated_at=? where id = ?"
        try db.execute(updateSQL, args: status.rawValue,updatedAt.timeIntervalSince1970,noteId)
    }
    
    func delete( _ id:String) throws {
        let delSQL = "delete from note where id = ?"
        try db.execute(delSQL, args: id)
    }
    
    func removeTrashedNotes() throws {
        let delSQL = "delete from note where status = ?"
        try db.execute(delSQL, args: NoteStatus.trash.rawValue)
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
        let status = row["status"] as! Int
        let createdAt = Date(timeIntervalSince1970:  row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970:  row["updated_at"] as! Double)
        return  Note(id: id,title: title, content: content,status: NoteStatus.init(rawValue: status)!, createdAt: createdAt, updatedAt: updatedAt)
    }
}
