//
//  Tag.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import DeepDiff

struct Tag:DiffAware {
    
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
    
    init(id:String = UUID.init().uuidString,title:String,icon:String="",createdAt:Date,updatedAt:Date) {
        self.id = id
        self.icon = icon
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    

    typealias DiffId = String
    var diffId: DiffId { return self.id }
    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        a.id == b.id && a.title  ==  b.title
    }
}

extension Tag:SQLTable {
    static var createStatement: String {
        return  """
                CREATE TABLE IF NOT EXISTS "tag" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "title" TEXT UNIQUE NOT NULL,
                  "icon" TEXT NOT NULL,
                  "created_at" TIMESTAMP,
                  "updated_at" TIMESTAMP
                );
        """
    }
}
