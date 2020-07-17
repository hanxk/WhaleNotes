//
//  Space.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct Space {
    var id:String = UUID.init().uuidString
    // 收集板
    var collectBoardId:String = ""
    var boardGroupId:String = ""
    var categoryGroupId:String = ""
    var createdAt:Date = Date()
}
//TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
extension Space: SQLTable {
  static var createStatement: String {
    return """
        CREATE TABLE IF NOT EXISTS "space" (
          "id" TEXT PRIMARY KEY NOT NULL,
          "collect_board_id" TEXT UNIQUE NOT NULL,
          "board_group_id" TEXT UNIQUE NOT NULL,
          "category_group_id" TEXT UNIQUE NOT NULL,
          "created_at" DATE DEFAULT (datetime('now')),
          FOREIGN KEY("collect_board_id") REFERENCES block(id),
          FOREIGN KEY("board_group_id") REFERENCES block(id),
          FOREIGN KEY("category_group_id") REFERENCES block(id)
        )
    """
  }
}
