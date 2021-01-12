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
    var status:NoteStatus =  .normal
    var createdAt:Date!
    var updatedAt:Date!
    
    init() {
        let date =  Date()
        self.createdAt = date
        self.updatedAt = date
    }
    
    init(id:String,title:String,content:String,status:NoteStatus = .normal,createdAt:Date,updatedAt:Date) {
        self.id = id
        self.title = title
        self.content = content
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


enum NoteStatus: Int,Codable {
    case trash = -1
    case normal = 1
    case archive = 2
}

extension Note:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "note" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "title" TEXT,
                      "content" TEXT,
                      "status" INTEGER,
                      "created_at" TIMESTAMP,
                      "updated_at" TIMESTAMP
                    );
        """
    }
}
