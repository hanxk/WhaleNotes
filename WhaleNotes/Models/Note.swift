//
//  Note.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct Note {
    var id:String = UUID.init().uuidString
    var title:String = ""
    var content:String = ""
    var createdAt:Date!
    var updatedAt:Date!
    
    init() {
        let date =  Date()
        self.createdAt = date
        self.updatedAt = date
    }
    
    init(id:String,title:String,content:String,createdAt:Date,updatedAt:Date) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Note:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "note" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "title" TEXT,
                      "content" TEXT,
                      "created_at" TIMESTAMP,
                      "updated_at" TIMESTAMP
                    );
        """
    }
}
