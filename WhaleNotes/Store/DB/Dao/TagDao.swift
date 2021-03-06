//
//  TagDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

class TagDao {
    
    private  var db: SQLiteDatabase!
    
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
    
}


extension TagDao {
    func insert( _ tag:Tag) throws {
        let insertSQL = "INSERT OR REPLACE INTO tag(id,title,icon,is_del,is_local,created_at,updated_at) VALUES(?,?,?,?,?,?,?)"
        try db.execute(insertSQL, args: tag.id,tag.title,tag.icon,tag.isDel ? 1 : 0,tag.isLocal ? 1 : 0,tag.createdAt.timeIntervalSince1970,tag.updatedAt.timeIntervalSince1970)
    }
    
    func query() throws -> [Tag]  {
        let selectSQL = "SELECT * FROM tag ORDER BY title"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    //#123 #123/456
    func queryChildTags(parentTitle:String) throws -> [Tag]  {
        let selectSQL = "SELECT * FROM tag where title like '\(parentTitle)/%' ORDER BY title"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func queryByTitle(title:String) throws -> Tag? {
        let selectSQL = "SELECT * FROM tag WHERE title = ?"
        let rows = try db.query(selectSQL,args: title)
        if rows.count == 0 { return nil}
        return extract(row: rows[0])
    }
    
    func queryByTitles(_ titles:[String]) throws -> [Tag] {
        let titlePara = "\"" + titles.joined(separator: "\",\"") + "\""
        let selectSQL = "SELECT * FROM tag WHERE  is_del = 0 AND  title in (\(titlePara))"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    
    
    func queryByIDs(_ ids:[String]) throws -> [Tag] {
        let idPara = "\"" + ids.joined(separator: "\",\"") + "\""
        let selectSQL = "SELECT * FROM tag WHERE id in (\(idPara))"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func queryDelTags() throws -> [Tag] {
        let selectSQL = """
                            SELECT * FROM tag WHERE is_del = 1
                            """
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func queryValids() throws -> [Tag]  {
        let selectSQL = """
                            select * from tag where is_del = 0 AND id in (
                                select tag_id from note_tag
                                WHERE note_id in (SELECT id FROM note where status = ?)
                            )
                            order by title
                            """
        let rows = try db.query(selectSQL,args:NoteStatus.normal.rawValue)
        return extract(rows: rows)
    }
    
    func queryByKeyword(_ keyword:String) throws -> [(String,Tag)]  {
        let selectSQL  = """
                        SELECT tag.*,n_t.note_id FROM (
                            SELECT * FROM note_tag
                            WHERE note_id in (select id from note where status != -1 AND (title  like '%\(keyword)%'  or content like '%\(keyword)%'))
                        ) AS n_t JOIN tag ON tag.id = n_t.tag_id  ORDER BY tag.title
                    """
        let rows = try db.query(selectSQL)
        var result: [(String,Tag)] = []
        for row in rows {
            let tag = extract(row: row)
            let noteId = row["note_id"] as! String
            result.append((noteId,tag))
        }
        return result
    }
    
    func queryByTag(noteIds:[String]) throws -> [(String,Tag)]  {
        let sqlIds = noteIds.map{"'\($0)'"}.joined(separator: ",")
        let selectSQL  = """
                        SELECT tag.*,n_t.note_id FROM (
                            SELECT * FROM note_tag
                            WHERE note_id in (\(sqlIds))
                        ) AS n_t JOIN tag ON tag.id = n_t.tag_id  ORDER BY tag.title
                    """
        let rows = try db.query(selectSQL)
        var result: [(String,Tag)] = []
        for row in rows {
            let tag = extract(row: row)
            let noteId = row["note_id"] as! String
            result.append((noteId,tag))
        }
        return result
    }
    
    func queryByTag(tagId:String = "",status:NoteStatus =  .normal) throws -> [(String,Tag)]  {
        let tagQuery = tagId ==  "" ? "" : " and tag_id = \"\(tagId)\""
        let selectSQL  = """
                        SELECT tag.*,n_t.note_id FROM (
                            SELECT * FROM note_tag
                            WHERE note_id in (SELECT id FROM note where status = ?) \(tagQuery)
                        ) AS n_t JOIN tag ON tag.id = n_t.tag_id  ORDER BY tag.title
                    """
        let rows = try db.query(selectSQL,args: status.rawValue)
        var result: [(String,Tag)] = []
        for row in rows {
            let tag = extract(row: row)
            let noteId = row["note_id"] as! String
            result.append((noteId,tag))
        }
        return result
    }
    
    func queryByNote(noteId:String) throws -> [Tag]  {
        let selectSQL  = """
                        SELECT tag.* FROM note_tag
                        JOIN tag ON tag.id = note_tag.tag_id AND note_tag.note_id = ? ORDER BY tag.title
                    """
        let rows = try db.query(selectSQL,args:noteId)
        return extract(rows: rows)
    }
    
    
    func queryFromDate(_ fromDate:Date) throws -> [Tag]  {
        let selectSQL = "SELECT * FROM tag WHERE updated_at > ?"
        let rows = try db.query(selectSQL,args: fromDate.timeIntervalSince1970)
        return extract(rows: rows)
    }
    
    func search(_ keyword:String) throws -> [Tag]  {
        var selectSQL:String
        if keyword.isNotEmpty {
            selectSQL = "select * from tag  where title like '%\(keyword)%' order by title"
        }else  {
            selectSQL = "select * from tag  order by title"
        }
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    
    func update( _ tag:Tag) throws {
        let updateSQL = "update or ignore tag set title = ?,icon = ?,updated_at=\(Date().timeIntervalSince1970) where id = ?"
        try db.execute(updateSQL, args: tag.title,tag.icon,tag.id)
    }
    
    func deleteForever( _ id:String) throws {
        let delSQL = "delete from tag where id = ?"
        try db.execute(delSQL, args: id)
    }
    
    func markUnusedTags2Deled() throws {
        let delSQL = "UPDATE tag set is_del = 1,updated_at=\(Date().timeIntervalSince1970) WHERE id not in (select tag_id from note_tag)"
        try db.execute(delSQL)
    }
    
    func updateTags2Del(tagTitle:String) throws {
        let delSQL = "UPDATE tag set is_del = 1,updated_at=\(Date().timeIntervalSince1970) WHERE title = ? OR title LIKE '\(tagTitle)/%'"
        try db.execute(delSQL, args: tagTitle)
        logi("删除了\(db.changes)")
    }
    
    func deleteLocalTags(tagTitle:String) throws {
        let delSQL = "DELEFT FROM TAG WHERE is_local = 1 AND (title = ? OR title LIKE '\(tagTitle)/%')"
        try db.execute(delSQL, args: tagTitle)
    }
    
    func queryFromUpdatedDate(date:Date) throws -> [Tag]  {
        let selectSQL = "select * from tag where updated_at > ?"
        let rows = try db.query(selectSQL,args: date.timeIntervalSince1970)
        return extract(rows: rows)
    }
    
}


extension TagDao {
    
    fileprivate func extract(rows: [Row]) -> [Tag] {
        var tags:[Tag] = []
        for row in rows {
            tags.append(extract(row: row))
        }
        return tags
    }
    
    fileprivate func extract(row:Row) -> Tag {
        let id = row["id"] as! String
        let title = row["title"] as! String
        let icon = row["icon"] as! String
        let isDel = (row["is_del"] as! Int) == 1
        let isLocal = (row["is_local"] as! Int) == 1
        let createdAt = Date(timeIntervalSince1970:  row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970:  row["updated_at"] as! Double)
        return Tag(id: id, title: title,icon: icon,isDel: isDel,isLocal: isLocal,createdAt: createdAt, updatedAt: updatedAt)
    }
}
