//
//  NoteTagDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

class NoteTagDao {
    
    private  var db: SQLiteDatabase!
    
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
    
}


extension NoteTagDao {
    func insert( _ noteTag:NoteTag) throws {
        let insertSQL = "INSERT OR IGNORE INTO note_tag(note_id,tag_id) values(?,?)"
        try db.execute(insertSQL, args: noteTag.noteId,noteTag.tagId)
    }
    
    func delete(noteId:String) throws {
        let delSQL = "delete from note_tag where note_id = ?"
        try db.execute(delSQL, args: noteId)
    }
    
    func deleteLocal(tagTitle:String) throws {
        let delSQL = "DELEFT FROM note_tag tag_id in (SELECT id FROM tag WHERE is_local = 1 AND (title = ? OR title LIKE '\(tagTitle)/%'))"
        try db.execute(delSQL, args: tagTitle)
    }
    
    func delete(noteId:String,tagId:String) throws {
        let delSQL = "delete from note_tag where note_id = ? and tag_id = ?"
        try db.execute(delSQL, args: noteId,tagId)
    }
}


extension NoteTagDao {
    
    fileprivate func extract(rows: [Row]) -> [NoteTag] {
        var tags:[NoteTag] = []
        for row in rows {
            tags.append(extract(row: row))
        }
        return tags
    }
    
    fileprivate func extract(row:Row) -> NoteTag {
        let noteId = row["note_id"] as! String
        let tagId = row["tag_id"] as! String
        return NoteTag(noteId: noteId, tagId: tagId)
    }
}
