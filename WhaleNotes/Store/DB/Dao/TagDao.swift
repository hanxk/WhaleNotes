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
        let insertSQL = "INSERT INTO tag(id,title,icon,created_at,updated_at) VALUES(?,?,?,?,?)"
        try db.execute(insertSQL, args: tag.id,tag.title,tag.icon,tag.createdAt.timeIntervalSince1970,tag.updatedAt.timeIntervalSince1970)
//        return db.changes
    }
    
    func query() throws -> [Tag]  {
        let selectSQL = "SELECT * FROM tag ORDER BY title"
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
//        let titlePara = titles.joined(separator: ",")
        
        
        let titlePara = "\"" + titles.joined(separator: "\",\"") + "\""
        
//        let titlePara = \""  + titles.joined(separator: "\",\"") + \""
        let selectSQL = "SELECT * FROM tag WHERE title in (\(titlePara))"
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func queryValids() throws -> [Tag]  {
        let selectSQL = """
                            SELECT * FROM (
                                    select * from tag where id in (select tag_id from note_tag)
                               )
                            order by title
                            """
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    func queryByTag(tagId:String = "") throws -> [(String,Tag)]  {
      let selectSQL  = """
                        SELECT tag.*,n_t.note_id FROM (
                            SELECT * FROM note_tag
                            WHERE note_id in (SELECT id FROM note)
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
    
    func queryByNote(noteId:String) throws -> [Tag]  {
      let selectSQL  = """
                        SELECT tag.* FROM note_tag
                        JOIN tag ON tag.id = note_tag.tag_id AND note_tag.note_id = ? ORDER BY tag.title
                    """
        let rows = try db.query(selectSQL,args:noteId)
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
        let updateSQL = "update tag set title = ?,icon = ?,updated_at=strftime('%s', 'now') where id = ?"
        try db.execute(updateSQL, args: tag.title,tag.icon,tag.id)
    }
    
    func delete( _ id:String) throws {
        let delSQL = "delete from tag where id = ?"
        try db.execute(delSQL, args: id)
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
//        let parent = row["parent"] as? String
        let createdAt = Date(timeIntervalSince1970:  row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970:  row["updated_at"] as! Double)
        return Tag(id: id, title: title,icon: icon,createdAt: createdAt, updatedAt: updatedAt)
    }
}
