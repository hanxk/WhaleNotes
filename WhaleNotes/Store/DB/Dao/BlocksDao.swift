//
//  BlockDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

enum Field_Blocks{
    static let id = Expression<Int64>("id")
    static let type = Expression<String>("type")
    static let text = Expression<String>("text")
    static let sort = Expression<Double>("sort")
    static let isChecked = Expression<Bool>("is_checked")
    static let isExpand = Expression<Bool>("is_expand")
    static let source = Expression<String>("source")
    static let createdAt = Expression<Date>("created_at")
    static let noteId = Expression<Int64>("note_id")
    static let parentBlockId = Expression<Int64>("parent_block_id")
    static let properties = Expression<String>("properties")
}

class BlocksDao {
    
    private var table: Table!
    
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        table = self.createTable()
    }
    
    func insert( _ block:Block) throws -> Int64 {
        let insertBlock = self.generateBookInsert(block: block,conflict: .ignore)
        let rowId = try db.run(insertBlock)
        return rowId
    }
    
    
    func updateText(id:Int64,text:String) throws -> Bool {
        let blockTable = table.filter(Field_Blocks.id == id)
        let rows = try db.run(blockTable.update(Field_Blocks.text <- text))
        return rows == 1
    }
    
    
    func updateBlock(block:Block) throws -> Bool {
        let blockTable = table.filter(Field_Blocks.id == block.id)
        let rows = try db.run(blockTable.update(
                                              Field_Blocks.type <- block.type,
                                              Field_Blocks.text <- block.text,
                                              Field_Blocks.sort <- block.sort,
                                              Field_Blocks.isChecked <- block.isChecked,
                                              Field_Blocks.isExpand <- block.isExpand,
                                              Field_Blocks.source <- block.source,
                                              Field_Blocks.noteId <- block.noteId,
                                              Field_Blocks.parentBlockId <- block.parentBlockId,
                                              Field_Blocks.properties <- block.properties
                                            ))
        
        return rows == 1
    }
    
    
    func deleteBlock(blockId:Int64) throws -> Bool {
        let blockTable = table.filter(Field_Blocks.id == blockId)
        let rows = try db.run(blockTable.delete())
        return rows > 0
    }
    
    func deleteBlocksByNoteId(noteId: Int64)  throws -> Bool {
      let blockTable = table.filter(Field_Blocks.noteId == noteId)
      let rows = try db.run(blockTable.delete())
      return rows > 0
    }
    
    func query(noteId:Int64) throws ->[Block] {
        let query = table.filter(Field_Blocks.noteId == noteId).order(Field_Blocks.sort.asc)
        let blockRows = try db.prepare(query)
        var blocks:[Block] = []
        for row in blockRows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
}


extension BlocksDao {
    fileprivate func createTable() -> Table {
        let tableBlock = Table("blocks")
        
        do {
            try! db.run(
                tableBlock.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Blocks.id,primaryKey: .autoincrement)
                    builder.column(Field_Blocks.type)
                    builder.column(Field_Blocks.text)
                    builder.column(Field_Blocks.sort)
                    builder.column(Field_Blocks.isChecked)
                    builder.column(Field_Blocks.isExpand)
                    builder.column(Field_Blocks.source)
                    builder.column(Field_Blocks.createdAt)
                    builder.column(Field_Blocks.noteId)
                    builder.column(Field_Blocks.parentBlockId)
                    builder.column(Field_Blocks.properties)
                })
            )
        }
        return tableBlock
    }
    
    
    func generateBookInsert(block: Block,conflict:OnConflict = OnConflict.fail) -> Insert {
        
        if block.id > 0 {
            return table.insert(or: conflict,
                                Field_Blocks.id <- block.id,
                                Field_Blocks.type <- block.type,
                                Field_Blocks.text <- block.text,
                                Field_Blocks.sort <- block.sort,
                                Field_Blocks.isChecked <- block.isChecked,
                                Field_Blocks.isExpand <- block.isExpand,
                                Field_Blocks.source <- block.source,
                                Field_Blocks.createdAt <- block.createdAt,
                                Field_Blocks.noteId <- block.noteId,
                                Field_Blocks.parentBlockId <- block.parentBlockId,
                                Field_Blocks.properties <- block.properties
            )
        }
        return table.insert(or: conflict,
                            Field_Blocks.type <- block.type,
                            Field_Blocks.text <- block.text,
                            Field_Blocks.sort <- block.sort,
                            Field_Blocks.isChecked <- block.isChecked,
                            Field_Blocks.isExpand <- block.isExpand,
                            Field_Blocks.source <- block.source,
                            Field_Blocks.createdAt <- block.createdAt,
                            Field_Blocks.noteId <- block.noteId,
                            Field_Blocks.parentBlockId <- block.parentBlockId,
                            Field_Blocks.properties <- block.properties
        )
        
    }
    
    fileprivate func generateBlock(row: Row) -> Block {
        let block = Block(id: row[Field_Blocks.id], type: row[Field_Blocks.type], text: row[Field_Blocks.text], isChecked: row[Field_Blocks.isChecked], isExpand: row[Field_Blocks.isExpand], source: row[Field_Blocks.source], createdAt: row[Field_Blocks.createdAt],sort: row[Field_Blocks.sort], noteId: row[Field_Blocks.noteId],parentBlockId:row[Field_Blocks.parentBlockId],properties: row[Field_Blocks.properties])
        return block
    }
}
