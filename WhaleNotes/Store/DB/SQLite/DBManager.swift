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
    
    
    private(set) var noteDao:NoteDao!
    private(set) var tagDao:TagDao!
    private(set) var noteTagDao:NoteTagDao!
    private(set) var noteFileDao:NoteFileDao!
    
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
        
        try db.createTable(table: Note.self)
        try db.createTable(table: Tag.self)
        try db.createTable(table: NoteTag.self)
        try db.createTable(table: NoteFile.self)
        
        self.noteDao = NoteDao(dbCon: db)
        self.tagDao = TagDao(dbCon: db)
        self.noteTagDao = NoteTagDao(dbCon: db)
        self.noteFileDao = NoteFileDao(dbCon: db)
    }
    
}
