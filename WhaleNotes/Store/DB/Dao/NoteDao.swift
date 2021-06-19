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
        let insertSQL = "INSERT OR REPLACE INTO note(id,title,content,status,is_del,is_local,created_at,updated_at) values(?,?,?,?,?,?,?,?)"
        try db.execute(insertSQL, args: note.id,note.title,note.content,note.status.rawValue,note.isDel ?1:0,note.isLocal ?1:0,note.createdAt.timeIntervalSince1970,note.updatedAt.timeIntervalSince1970)
    }
    
    func query(tagId:String) throws -> [Note]  {
        let selectSQL = "select * from note where id in (select note_id from note_tag where tag_id = ?) order by created_at desc"
        let rows = try db.query(selectSQL,args: tagId)
        return extract(rows: rows)
    }
    func query(tagTitle:String) throws -> [Note]  {
        let selectSQL = "select * from note where id in (SELECT note_id FROM note_tag INNER JOIN tag ON tag.id = note_tag.tag_id AND (tag.title = ? OR tag.title LIKE '\(tagTitle)/%'))"
        let rows = try db.query(selectSQL,args: tagTitle)
        return extract(rows: rows)
    }
    
    func queryPage(tagId:String,offset:Int,pageSize:Int = PAGESIZE) throws -> [Note]  {
//        let offset = PAGESIZE * pageIndex
        let selectSQL = "select * from note where is_del == 0 AND id in (select note_id from note_tag where tag_id = ?) order by created_at desc  LIMIT \(pageSize) OFFSET \(offset)"
        let rows = try db.query(selectSQL,args: tagId)
        return extract(rows: rows)
    }
    
    func query(status:NoteStatus = .normal,offset:Int) throws -> [Note]  {
        let selectSQL = "select * from note where status  = ? AND is_del == 0 order by created_at desc LIMIT \(PAGESIZE) OFFSET \(offset)"
        let rows = try db.query(selectSQL,args: status.rawValue)
        return extract(rows: rows)
    }
    
    func query(keyword:String,offset:Int) throws -> [Note]  {
//        let offset = PAGESIZE * pageIndex
        let selectSQL = "select * from note where status != -1  AND (title  like '%\(keyword)%'  or content like '%\(keyword)%') order by created_at desc LIMIT \(PAGESIZE) OFFSET \(offset)"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func queryFromDate(_ from:Date) throws -> [Note]  {
        let selectSQL = "select * from note where updated_at > ?"
        let rows = try db.query(selectSQL,args: from.timeIntervalSince1970)
        return extract(rows: rows)
    }
    
    
    
    func query(id:String) throws -> Note?  {
        let selectSQL = "select * from note where id = ?"
        let rows = try db.query(selectSQL,args:id)
        if rows.count == 0 { return nil}
        return extract(row: rows[0])
    }
    
//    func resetUpdateChangedNotes() throws {
//        let updateSQL = "update note set changed_type = \(ChangedType.none.rawValue) where changed_type = \(ChangedType.update.rawValue)"
//        try db.execute(updateSQL)
//    }
//    func resetDeleteChangedNotes() throws {
//        let updateSQL = "update note set changed_type = \(ChangedType.none) where changed_type = \(ChangedType.delete.rawValue)"
//        try db.execute(updateSQL)
//    }
    
    
    func queryFromUpdatedDate(date:Date) throws -> [Note]  {
        let selectSQL = "select * from note where updated_at > ?"
        let rows = try db.query(selectSQL,args: date.timeIntervalSince1970)
        return extract(rows: rows)
    }
    
    func queryByIDs(_ ids:[String]) throws -> [Note] {
        let idPara = "\"" + ids.joined(separator: "\",\"") + "\""
        let selectSQL = "SELECT * FROM note WHERE id in (\(idPara))"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func update( _ note:Note) throws {
        let updateSQL = "update note set title = ?,content = ?,status = ?,updated_at= \(note.updatedAt.timeIntervalSince1970) where id = ?"
        try db.execute(updateSQL, args: note.title,note.content,note.status.rawValue,note.id)
    }
    
    func updateContent( _ content:String,noteId:String,updatedAt:Date) throws {
        let updateSQL = "update note set  content = ?, updated_at=? where id = ?"
        try db.execute(updateSQL, args: content,updatedAt.timeIntervalSince1970,noteId)
    }
    
    func updateTitle( _ title:String,noteId:String,updatedAt:Date) throws {
        let updateSQL = "update note set  title = ?, updated_at=? where id = ?"
        try db.execute(updateSQL, args: title,updatedAt.timeIntervalSince1970,noteId)
    }
    
    func updateStatus( _ status:NoteStatus,noteId:String,updatedAt:Date) throws {
        let updateSQL = "update note set status = ?,updated_at=? where id = ?"
        try db.execute(updateSQL, args: status.rawValue,updatedAt.timeIntervalSince1970,noteId)
    }
    
    func mark2Del( _ id:String) throws {
        let sql = "UPDATE note SET is_del = 1,updated_at = \(Date().timeIntervalSince1970) WHERE id = ?"
        try db.execute(sql, args: id)
    }
    
    func delete( _ id:String) throws {
        let sql:String = "delete from note where id = ?"
        try db.execute(sql, args: id)
    }
    
    // soft delete
    func removeTrashedNotes() throws {
        let delSQL = "UPDATE note SET is_del = 1,updated_at=?  WHERE status = ?"
        try db.execute(delSQL, args:Date().timeIntervalSince1970, NoteStatus.trash.rawValue)
    }
    
    func updateNotes2Del(tag:Tag) throws {
        let delSQL = "UPDATE note SET is_del = 1,updated_at= ? WHERE id in (SELECT note_id FROM note_tag INNER JOIN tag ON tag.id = note_tag.tag_id AND (tag.title = ? OR tag.title LIKE '\(tag.title)/%')) "
        try db.execute(delSQL, args:Date().timeIntervalSince1970,tag.title)
    }
    
    func deleteLocalNotes(tag:Tag) throws {
        let delSQL = "DELETE FROM note WHERE is_local = 1 AND ( id in (SELECT note_id FROM note_tag INNER JOIN tag ON tag.id = note_tag.tag_id AND (tag.title = ? OR tag.title LIKE '\(tag.title)/%'))) "
        try db.execute(delSQL, args:Date().timeIntervalSince1970,tag.title)
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
        var status = NoteStatus.normal.rawValue
        if let statusV = row["status"] as? Int {
            status = statusV
        }
        let isDel = (row["is_del"] as! Int) == 1
        let isLocal = (row["is_local"] as! Int) == 1
        let createdAt = Date(timeIntervalSince1970:  row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970:  row["updated_at"] as! Double)
        return  Note(id: id,title: title, content: content,status: NoteStatus.init(rawValue: status)!,isDel: isDel,isLocal:isLocal,createdAt: createdAt, updatedAt: updatedAt)
    }
}
