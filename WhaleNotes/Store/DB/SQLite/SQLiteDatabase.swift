//
//  SQLiteDatabase.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import sqlite3

class SQLiteDatabase {
    private let dbPointer: OpaquePointer?
    private init(dbPointer: OpaquePointer?) {
        self.dbPointer = dbPointer
    }
    
    var errorMessage: String {
        if let errorPointer = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorPointer)
            return errorMessage
        } else {
            return "No error message provided from sqlite."
        }
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    static func open(path: String) throws -> SQLiteDatabase {
        var db: OpaquePointer?
        // 1
        if sqlite3_open(path, &db) == SQLITE_OK {
            // 2
            return SQLiteDatabase(dbPointer: db)
        } else {
            // 3
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            if let errorPointer = sqlite3_errmsg(db) {
                let message = String(cString: errorPointer)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
}

extension SQLiteDatabase {
    func prepareStatement(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            print(sql)
            throw SQLiteError.Prepare(message: errorMessage)
        }
        return statement
    }
}

extension SQLiteDatabase {
    func createTable(table: SQLTable.Type) throws {
        // 1
        let createTableStatement = try prepareStatement(sql: table.createStatement)
        // 2
        defer {
            sqlite3_finalize(createTableStatement)
        }
        // 3
        guard sqlite3_step(createTableStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
}

extension SQLiteDatabase {
    
    private func prepare(sql:String,args:[Any]=[]) throws -> SQLStatement {
        let statement = try prepareStatement(sql: sql)
        var result:Int32 = SQLITE_OK
        for (index,arg) in args.enumerated() {
            let index = Int32(index+1)
            if arg is String {
                let str = (arg as! NSString).utf8String
                result = sqlite3_bind_text(statement,index,str, -1, nil)
            }else if arg is Int {
                result = sqlite3_bind_int(statement, index, Int32(arg as! Int))
            }else if arg is Double {
                result = sqlite3_bind_double(statement, index, arg as! Double)
            }
            if result != SQLITE_OK {
                throw SQLiteError.Bind(message: errorMessage)
            }
        }
        return SQLStatement(statement: statement!)
    }
    
}

extension SQLiteDatabase {
    
    func execute(_ sql:String,args:Any...) throws  {
        let stmt = try self.prepare(sql: sql, args: args)
        try stmt.run()
        
        logi("数据影响：\(self.changes)")
    }
    
    var changes:Int {
        return Int(sqlite3_changes(dbPointer))
    }
    
    func query(_ sql:String,args:Any...) throws -> [Row]  {
        let stmt = try self.prepare(sql: sql, args: args)
        return try stmt.query()
    }
    
    func scalar(_ sql:String,args:Any...) throws -> Int  {
        let stmt = try self.prepare(sql: sql, args: args)
        return try stmt.scalar()
    }
    
    func transaction(_ transFunc:() throws ->Void) throws {
        do {
            _ = try self.execute(DBConstants.SQL_TRANS_BEGIN)
            try transFunc()
            _ = try self.execute(DBConstants.SQL_TRANS_COMMIT)
        }catch {
            _ = try self.execute(DBConstants.SQL_TRANS_ROLLBACK)
            throw error
        }
    }
    
    private func isUserSQL(_ sql:String) -> Bool {
        return sql != DBConstants.SQL_TRANS_BEGIN  &&
            sql != DBConstants.SQL_TRANS_COMMIT &&
            sql != DBConstants.SQL_TRANS_ROLLBACK
    }
}



extension SQLiteDatabase {
    
    func json(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    
    
}


extension String {
//    func utf8DecodedString()-> String {
//         let data = self.data(using: .utf8)
//         if let message = String(data: data!, encoding: .nonLossyASCII){
//                return message
//          }
//          return ""
//    }
//
//    func utf8EncodedString()-> String {
//         let messageData = self.data(using: .nonLossyASCII)
//         let text = String(data: messageData!, encoding: .utf8)
//         return text!
//    }
}


enum DBConstants {
    static let SQL_TRANS_BEGIN = "BEGIN EXCLUSIVE"
    static let SQL_TRANS_COMMIT = "COMMIT"
    static let SQL_TRANS_ROLLBACK = "ROLLBACK"
}
