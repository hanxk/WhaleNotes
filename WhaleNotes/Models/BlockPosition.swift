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
    var blockId:String = ""
    var ownerId:String = ""
    var position:Double = 65536
}

extension BlockPosition:SQLTable {
    static var createStatement: String {
        return  """
                CREATE TABLE IF NOT EXISTS "block_position" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "block_id" TEXT NOT NULL,
                  "owner_id" TEXT NOT NULL,
                  "position" REAL NOT NULL,
                  UNIQUE("block_id","owner_id"),
                  FOREIGN KEY("block_id") REFERENCES block(id),
                  FOREIGN KEY("owner_id") REFERENCES block(id)
                );
        """
    }
}

