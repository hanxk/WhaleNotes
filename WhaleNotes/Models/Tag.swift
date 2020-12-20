//
//  Tag.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct Tag {
    var id:String = UUID.init().uuidString
    var title:String = ""
    var icon:String = ""
    var createdAt:Date!
    var updatedAt:Date!
    
    
    init() {
        let date =  Date()
        self.createdAt = date
        self.updatedAt = date
    }
    
    init(id:String,title:String,icon:String,createdAt:Date,updatedAt:Date) {
        self.id = id
        self.icon = icon
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Tag:SQLTable {
    static var createStatement: String {
        return  """
                CREATE TABLE IF NOT EXISTS "tag" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "title" TEXT NOT NULL,
                  "icon" TEXT NOT NULL,
                  "created_at" TIMESTAMP,
                  "updated_at" TIMESTAMP
                );
        """
    }
}
