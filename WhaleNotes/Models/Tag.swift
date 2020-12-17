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
    var icon:String = ""
    var title:String = ""
    var parent:String? = nil
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
}

extension Tag:SQLTable {
    static var createStatement: String {
        return  """
                CREATE TABLE IF NOT EXISTS "tag" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "icon" TEXT NOT NULL,
                  "title" TEXT NOT NULL,
                  "parent" TEXT,
                  FOREIGN KEY("parent") REFERENCES tag(id)
                );
        """
    }
}
