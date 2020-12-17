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
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
}

extension Note:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "note" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "title" TEXT,
                      "content" TEXT,
                      "created_at" DATE DEFAULT (datetime('now')),
                      "updated_at" DATE DEFAULT (datetime('now'))
                    );
        """
    }
}
