//
//  BlockDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

fileprivate enum Field_Block{
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

class BlockDao {
    
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
        let blockTable = table.filter(Field_Block.id == id)
        let rows = try db.run(blockTable.update(Field_Block.text <- text))
        return rows == 1
    }
    
    
    func updateBlock(block:Block) throws -> Bool {
        let blockTable = table.filter(Field_Block.id == block.id)
        let rows = try db.run(blockTable.update(
                                              Field_Block.type <- block.type,
                                              Field_Block.text <- block.text,
                                              Field_Block.sort <- block.sort,
                                              Field_Block.isChecked <- block.isChecked,
                                              Field_Block.isExpand <- block.isExpand,
                                              Field_Block.source <- block.source,
                                              Field_Block.noteId <- block.noteId,
                                              Field_Block.parentBlockId <- block.parentBlockId,
                                              Field_Block.properties <- block.properties
                                            ))
        
        return rows == 1
    }
    
    
    func deleteBlock(blockId:Int64) throws -> Bool {
        let blockTable = table.filter(Field_Block.id == blockId)
        let rows = try db.run(blockTable.delete())
        return rows > 0
    }
    
    func deleteBlocksByNoteId(noteId: Int64)  throws -> Bool {
      let blockTable = table.filter(Field_Block.noteId == noteId)
      let rows = try db.run(blockTable.delete())
      return rows > 0
    }
    
    func query(noteId:Int64) throws ->[Block] {
        let query = table.filter(Field_Block.noteId == noteId).order(Field_Block.sort.asc)
        let blockRows = try db.prepare(query)
        var blocks:[Block] = []
        for row in blockRows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
}


extension BlockDao {
    fileprivate func createTable() -> Table {
        let tableBlock = Table("block")
        
        do {
            try! db.run(
                tableBlock.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Block.id,primaryKey: .autoincrement)
                    builder.column(Field_Block.type)
                    builder.column(Field_Block.text)
                    builder.column(Field_Block.sort)
                    builder.column(Field_Block.isChecked)
                    builder.column(Field_Block.isExpand)
                    builder.column(Field_Block.source)
                    builder.column(Field_Block.createdAt)
                    builder.column(Field_Block.noteId)
                    builder.column(Field_Block.parentBlockId)
                    builder.column(Field_Block.properties)
                })
            )
        }
        return tableBlock
    }
    
    
    func generateBookInsert(block: Block,conflict:OnConflict = OnConflict.fail) -> Insert {
        
        if block.id > 0 {
            return table.insert(or: conflict,
                                Field_Block.id <- block.id,
                                Field_Block.type <- block.type,
                                Field_Block.text <- block.text,
                                Field_Block.sort <- block.sort,
                                Field_Block.isChecked <- block.isChecked,
                                Field_Block.isExpand <- block.isExpand,
                                Field_Block.source <- block.source,
                                Field_Block.createdAt <- block.createdAt,
                                Field_Block.noteId <- block.noteId,
                                Field_Block.parentBlockId <- block.parentBlockId,
                                Field_Block.properties <- block.properties
            )
        }
        return table.insert(or: conflict,
                            Field_Block.type <- block.type,
                            Field_Block.text <- block.text,
                            Field_Block.sort <- block.sort,
                            Field_Block.isChecked <- block.isChecked,
                            Field_Block.isExpand <- block.isExpand,
                            Field_Block.source <- block.source,
                            Field_Block.createdAt <- block.createdAt,
                            Field_Block.noteId <- block.noteId,
                            Field_Block.parentBlockId <- block.parentBlockId,
                            Field_Block.properties <- block.properties
        )
        
    }
    
    fileprivate func generateBlock(row: Row) -> Block {
        var block = Block(id: row[Field_Block.id], type: row[Field_Block.type], text: row[Field_Block.text], isChecked: row[Field_Block.isChecked], isExpand: row[Field_Block.isExpand], source: row[Field_Block.source], createdAt: row[Field_Block.createdAt],sort: row[Field_Block.sort], noteId: row[Field_Block.noteId],parentBlockId:row[Field_Block.parentBlockId])
        block.properties = row[Field_Block.properties]
        return block
    }
}
