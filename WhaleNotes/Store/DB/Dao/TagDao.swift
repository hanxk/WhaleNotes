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
    
    fileprivate func extract(rows: [Row]) -> [Tag] {
        var tags:[Tag] = []
        for row in rows {
            tags.append(extract(row: row))
        }
        return tags
    }
    
    fileprivate func extract(row:Row) -> Tag {
        let id = row["id"] as! String
        let icon = row["icon"] as! String
        let title = row["title"] as! String
        let parent = row["title"] as? String
        let createdAt = row["created_at"] as! Date
        let updatedAt = row["updated_at"] as! Date
        return Tag(id: id, icon: icon, title: title, parent: parent, createdAt: createdAt, updatedAt: updatedAt)
    }
}
