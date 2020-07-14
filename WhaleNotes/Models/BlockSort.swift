//
//  BlockSort.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/13.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct BlockPosition {
    var id:String = UUID.init().uuidString
    var ownerId:String = ""
    var blockId:String = ""
    var position:Double = 0
    
    init(id:String = UUID.init().uuidString,ownerId:String = "",blockId:String = "", position:Double = 0) {
        self.id = id
        self.ownerId = ownerId
        self.blockId = blockId
        self.position = position
    }
}

extension Block:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "block_position" (
                      "id" TEXT UNIQUE NOT NULL,
                      "parent_id" TEXT NOT NULL,
                      "type" TEXT NOT NULL,
                      "properties" JSON NOT NULL,
                      "content" JSON NOT NULL,
                      "parent_table" TEXT NOT NULL,
                      "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                      "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
        """
    }
}

