//
//  TypedRow.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

//import Foundation
//import SQLite
//
///// In case it's necessary to execute a SQL query that is currently not possible
///// to express in a type-safe manner using SQLite.swift library, prepare a raw
///// SQL statement and map the resulting rows to TypedRow, which will then cast
///// the column values to the user specified types.
/////
///// Example code:
/////
/////     let statement = try db.prepare("SELECT expo.id AS expo_id FROM expo")
/////     let rows = statement.typedRows()
/////     let expos = rows.map { let id = $0.i64("expo_id"); return ... }
//public final class TypedRow {
//  
//  private var columns: [String: Int]
//  private var values: [Binding?]
//  
//  public init(columns theColumns: [String: Int], values theValues: [Binding?]) {
//    
//    columns = theColumns
//    values = theValues
//  }
//  
//  public convenience init(columns: [String], values: [Binding?]) {
//    
//    self.init(columns: columns.invertedIndexedDictionary, values: values)
//  }
//  
//  private func value(for column: String) -> Binding? {
//    return values[columns[column]!]
//  }
//  
//  public func i64(_ column: String) -> Int64? {
//    return value(for: column) as? Int64
//  }
//  public func double(_ column: String) -> Double? {
//    return value(for: column) as? Double
//  }
//  
//  public func int(_ column: String) -> Int? {
//    return Int(truncatingIfNeeded: value(for: column) as! Int64)
//  }
//  
////  public func int(_ column: String) -> Int8? {
////    return value(for: column) as? Int8
////  }
//  
//  public func u32(_ column: String) -> UInt32? {
//    return value(for: column) as? UInt32
//  }
//  
//  public func bool(_ column: String) -> Bool {
//    return (value(for: column) as? Bool) ?? false
//  }
//  
//  public func string(_ column: String) -> String? {
//    return value(for: column) as? String
//  }
//  
//  public func date(_ column: String) -> Date? {
//    guard let rawValue = value(for: column) as? String else { return nil }
//    return rawValue.dateFromSQLiteTime()
//  }
//}
//
//fileprivate extension Array where Element: Hashable  {
//  
//  var invertedIndexedDictionary: [Element: Int] {
//    
//    var result: [Element: Int] = [:]
//    enumerated().forEach { result[$0.element] = $0.offset }
//    return result
//  }
//}
//
//public extension Statement {
//  
//  public func typedRows() -> [TypedRow] {
//    return map { TypedRow(columns: columnNames,  values: $0) }
//  }
//}
