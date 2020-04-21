//
//  SQLiteManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

// 数据库管理类
class SQLiteManager: NSObject {
  static let manager = SQLiteManager()
  private var db: Connection?
  private var table: Table?
  
  func getDB() -> Connection {
    
    if db == nil {
      
      let path = NSSearchPathForDirectoriesInDomains(
        .documentDirectory, .userDomainMask, true
        ).first!
      db = try! Connection("\(path)/WhaleNotes.sqlite3")
      db?.busyTimeout = 5.0
      
    }
    return db!
    
  }
  
}
