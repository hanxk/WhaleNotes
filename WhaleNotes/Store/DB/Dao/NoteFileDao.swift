//
//  NoteTagDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

class NoteFileDao {
    
    private  var db: SQLiteDatabase!
    
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
    
}


extension NoteFileDao {
    func insert( _ noteFile:NoteFile) throws {
        let insertSQL = "INSERT OR REPLACE INTO note_file(id,name,note_id,width,height,size,sort,suffix,created_at,updated_at) values(?,?,?,?,?,?,?,?,?,?)"
        try db.execute(insertSQL, args: noteFile.id,noteFile.name, noteFile.noteId,noteFile.width,noteFile.height,noteFile.size,noteFile.sort,noteFile.suffix, noteFile.createdAt.timeIntervalSince1970,noteFile.updatedAt.timeIntervalSince1970)
    }
    
    func delete(id:String) throws {
        let delSQL = "delete from note_file where id = ?"
        try db.execute(delSQL, args: id)
    }
    
    func queryByTag(noteIds:[String]) throws -> [String:[NoteFile]]  {
        let sqlIds = noteIds.map{"'\($0)'"}.joined(separator: ",")
        let selectSQL  = """
                        SELECT * FROM note_file WHERE note_id in (\(sqlIds))
                    """
        let rows = try db.query(selectSQL)
        var result:[String:[NoteFile]] = [:]
        for row in rows {
            let noteFile = extract(from: row)
            let noteId = row["note_id"] as! String
            if result[noteId] == nil {
                result[noteId] = [noteFile]
                continue
            }
            result[noteId]?.append(noteFile)
            
        }
        return result
    }
    
    func queryFromUpdatedDate(date:Date) throws -> [NoteFile]  {
        let selectSQL = "select * from note_file where updated_at > ?"
        let rows = try db.query(selectSQL,args: date.timeIntervalSince1970)
        return extract(rows: rows)
    }
}


extension NoteFileDao {
    
    fileprivate func extract(rows: [Row]) -> [NoteFile] {
        return rows.map { extract(from: $0) }
    }
    
    fileprivate func extract(from row: Row) -> NoteFile {
        let id = row["id"] as! String
        let name = row["name"] as! String
        let noteId = row["note_id"] as! String
        let width = row["width"] as? Double ?? 0
        let height = row["height"] as? Double ?? 0
        let size = row["size"] as? Int ?? 0
        let sort = row["sort"] as? Int ?? 0
        let suffix = row["suffix"] as! String
        
        let createdAt = Date(timeIntervalSince1970:  row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970:  row["updated_at"] as! Double)
        return NoteFile(id: id,name: name, noteId: noteId, width: width, height: height, size: size, sort: sort, suffix:  suffix, createdAt: createdAt, updatedAt: updatedAt)
    }
}
