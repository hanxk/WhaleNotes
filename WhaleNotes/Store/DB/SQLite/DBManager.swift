//
//  DBManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

// 数据库管理类
class DBManager: NSObject {
    static let shared = DBManager()
    private var _db: SQLiteDatabase!
    
    private(set) var blockDao:BlockDao!
    private(set) var blockPositionDao:BlockPositionDao!
    
    var db:SQLiteDatabase {
        return _db
    }
    
    func setup() {
        do {
            let path = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true
            ).first!
            print("db path: \(path)")
            let db = try SQLiteDatabase.open(path: "\(path)/WhaleNotes.sqlite3")
            self._db = db
            try self.setupTable()
        }catch {
            print(error)
        }
    }
    
    private func setupTable() throws {
        try db.createTable(table: Block.self)
        try db.createTable(table: BlockPosition.self)
        
        self.blockDao = BlockDao(dbCon: db)
        self.blockPositionDao = BlockPositionDao(dbCon: db)
    }
    
}
