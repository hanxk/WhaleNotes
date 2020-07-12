//
//  SQLite.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import sqlite3


enum SQLiteError: Error {
  case OpenDatabase(message: String)
  case Prepare(message: String)
  case Step(message: String)
  case Bind(message: String)
}





public struct Row {
    var values = [String: Any]()
    public subscript(key: String) -> Any? {
        get {
            return values[key]
        }
        set(newValue) {
            values[key] = newValue
        }
    }
    
}




protocol SQLTable {
  static var createStatement: String { get }
}
