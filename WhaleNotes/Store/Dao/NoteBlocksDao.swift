//
//  NoteBlocksDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite


enum Field_NoteBlock {
  static let id = Expression<Int64>("id")
  static let type = Expression<Int>("type")
  static let data = Expression<String>("data")
  static let noteId = Expression<Int64>("note_id")
  static let sort = Expression<Int>("sort")
}

class NoteBlocksDao {
  
  static let shared = NoteBlocksDao()
  private var tableNoteBlock: Table?
  fileprivate var db: Connection {
    return SQLiteManager.manager.getDB()
  }
  
  init() {
    _ = _getTableNoteBlock()
  }
  
  func insert( _ noteBlock:NoteBlock) throws -> Int64 {
    let insertNote = self._generateNoteInsert(noteBlock: noteBlock,conflict: .ignore)
    let rowId = try db.run(insertNote)
    return rowId
  }

  func update( _ noteBlock:NoteBlock) throws -> Int64 {
    let insertNote = self._generateNoteInsert(noteBlock: noteBlock,conflict: .replace)
    let rowId = try SQLiteManager.manager.getDB().run(insertNote)
    return rowId
  }

  func deleteForever(id:Int64) throws -> Int {
    let rowEffects = try db.run(_getTableNoteBlock().filter(Field_NoteBlock.id == id).delete())
    return rowEffects
  }

  func getNoteBlocks(noteId: Int64) throws -> [NoteBlock] {
    let noteBlockRows = try db
      .prepare(_getTableNoteBlock()
        .filter(Field_NoteBlock.noteId == noteId).order(Field_NoteBlock.sort.asc))
    var noteBlocks:[NoteBlock] = []
    for row in noteBlockRows {
      let noteBlock = _generateNoteBlock(row: row)
      noteBlocks.append(noteBlock)
    }
    return noteBlocks
  }
  
}


extension NoteBlocksDao {
  
  func createTableIfNotExists() {
    _ = _getTableNoteBlock()
  }
  
  fileprivate func _getTableNoteBlock() -> Table {
    
    if tableNoteBlock == nil {
      
      tableNoteBlock = Table("note_block")
      
      do {
        try! SQLiteManager.manager.getDB().run(
          tableNoteBlock!.create(ifNotExists: true, block: { (builder) in
            builder.column(Field_NoteBlock.id,primaryKey: .autoincrement)
            builder.column(Field_NoteBlock.type)
            builder.column(Field_NoteBlock.data)
            builder.column(Field_NoteBlock.noteId)
            builder.column(Field_NoteBlock.sort)
          })
        )
      }
      
    }
    return tableNoteBlock!
  }
  
  func _generateNoteInsert(noteBlock: NoteBlock,conflict:OnConflict = OnConflict.ignore) -> Insert {

    if noteBlock.id > 0 {
      return  _getTableNoteBlock().insert(or: conflict,
                                          Field_NoteBlock.id <- noteBlock.id,
                                          Field_NoteBlock.type <- noteBlock.type.rawValue,
                                          Field_NoteBlock.data <- noteBlock.toJSONData(),
                                          Field_NoteBlock.noteId <- noteBlock.noteId,
                                          Field_NoteBlock.sort <- noteBlock.sort
      )
    }
    return _getTableNoteBlock().insert(or: conflict,
                                     Field_NoteBlock.type <- noteBlock.type.rawValue,
                                     Field_NoteBlock.data <- noteBlock.toJSONData(),
                                     Field_NoteBlock.noteId <- noteBlock.noteId,
                                     Field_NoteBlock.sort <- noteBlock.sort
    )

  }
//
//
  func _generateNoteBlock(row: Row) -> NoteBlock {
    let noteBlock = NoteBlock(id: row[Field_NoteBlock.id],type: BlockType(rawValue: row[Field_NoteBlock.type])!,data: convertToDictionary(text: row[Field_NoteBlock.data]),sort: row[Field_NoteBlock.sort],noteId:row[Field_NoteBlock.noteId])
    return noteBlock
  }
    
    func convertToDictionary(text: String) -> [String: Any]? {
         if let data = text.data(using: .utf8) {
             do {
                 return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
             } catch {
                 print(error.localizedDescription)
             }
         }
         return nil
     }
  
}
