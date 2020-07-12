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
    var collectBoardId:String = ""
    var boardGroupIds:[String] = []
    var createdAt:Date = Date()
}
//TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
extension Space: SQLTable {
  static var createStatement: String {
    return """
        CREATE TABLE IF NOT EXISTS "space" (
          "id" TEXT UNIQUE NOT NULL,
          "collect_board_id" TEXT NOT NULL,
          "board_group_ids" JSON NOT NULL,
          "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """
  }
}
