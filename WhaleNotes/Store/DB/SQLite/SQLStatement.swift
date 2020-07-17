//
//  SQLStatement.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import sqlite3

class SQLStatement {
    var stmt: OpaquePointer!
    
    init(statement:OpaquePointer) {
        self.stmt = statement
    }
    
    func run() throws -> Int32{
        defer {
            sqlite3_finalize(stmt)
        }
        self.printSQL()
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(stmt))
            throw SQLiteError.Step(message: errorMessage)
        }
        return sqlite3_changes(stmt)
    }
    
    func query() throws -> [Row]  {
        defer {
            sqlite3_finalize(stmt)
        }
        self.printSQL()
        var rows:[Row] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let columnCount = sqlite3_column_count(stmt)
            let row = generateRow(columnCount: columnCount)
            rows.append(row)
        }
        return rows
    }
    
    private func printSQL() {
        let sql = String(cString:sqlite3_expanded_sql(stmt))
        print(sql)
    }
}

extension SQLStatement {
    private func generateRow(columnCount:Int32) -> Row {
        var row = Row()
        for i in 0..<columnCount {
            let index = Int32(i)
            let columnName = String(cString:sqlite3_column_name(stmt, index))
            let columnType = String(cString:sqlite3_column_decltype(stmt, index)).uppercased()
            
            let value = getColumnValue(index: index, type: columnType)
            row[columnName] = value
        }
        return row
    }
    
    func getColumnValue(index: Int32, type: String) -> Any? {
//        if type == "TIMESTAMP" {
//           print(type)
//        }
//        print(type)
        switch type {
        case "INT", "INTEGER", "TINYINT", "SMALLINT", "MEDIUMINT", "BIGINT", "UNSIGNED BIG INT", "INT2", "INT8":
            if sqlite3_column_type(stmt, index) == SQLITE_NULL {
                return nil
            }
            return Int(sqlite3_column_int(stmt, index))
        case "CHARACTER(20)", "VARCHAR(255)", "VARYING CHARACTER(255)", "NCHAR(55)", "NATIVE CHARACTER", "NVARCHAR(100)", "TEXT", "JSON","CLOB":
            let  text = sqlite3_column_text(stmt, index)!
            return String(cString: text)
        case "BLOB", "NONE":
            let blob = sqlite3_column_blob(stmt, index)
            if blob != nil {
                let size = sqlite3_column_bytes(stmt, index)
                return NSData(bytes: blob, length: Int(size))
            }
            return nil
        case "REAL","TIMESTAMP", "DOUBLE", "DOUBLE PRECISION", "FLOAT", "NUMERIC", "DECIMAL(10,5)":
            if sqlite3_column_type(stmt, index) == SQLITE_NULL {
                return nil
            }
            return Double(sqlite3_column_double(stmt, index))
        case "BOOLEAN":
            if sqlite3_column_type(stmt, index) == SQLITE_NULL {
                return nil
            }
            return sqlite3_column_int(stmt, index) != 0
        case "DATE", "DATETIME":
            let text = String(cString: sqlite3_column_text(stmt, index))
            let dateFormatter = DateFormatter()
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let utcDate = dateFormatter.date(from: text)!
            return utcDate.toLocalTime()
        default:
            print("SwiftData Warning -> Column: \(index) is of an unrecognized type, returning nil")
            return nil
        }
        
    }
    
    
    
}
