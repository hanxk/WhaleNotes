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
    static let updatedAt = Expression<Date>("updated_at")
    static let noteId = Expression<Int64>("note_id")
    static let parent = Expression<Int64>("parent")
    static let status = Expression<Int>("status")
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
    
    
    func updateUpdatedAt(id:Int64,updatedAt:Date) throws -> Bool {
        let blockTable = table.filter(Field_Block.id == id)
        let rows = try db.run(blockTable.update(Field_Block.updatedAt <- updatedAt))
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
            Field_Block.parent <- block.parent,
            Field_Block.status <- block.status,
            Field_Block.updatedAt <- block.updatedAt,
            Field_Block.properties <- block.properties.toJSON()
        ))
        return rows == 1
    }
    
    func updateNoteBlockStatus(boardId: Int,status:Int) throws -> Bool {
        let updateSql = """
        update block set status = \(status),updated_at = DATE('now') where id in (
        select section_note.noteId from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = \(boardId))
        )
        """
        try db.run(updateSql)
        return db.changes >= 0
    }
    
    
    func delete(id:Int64) throws -> Bool {
        let blockTable = table.filter(Field_Block.id == id)
        let rows = try db.run(blockTable.delete())
        return rows > 0
    }
    
    
    func delete(noteId:Int64,type:String) throws -> Bool {
        let blockTable = table.filter(Field_Block.noteId == noteId && Field_Block.type == type)
        let rows = try db.run(blockTable.delete())
        return rows > 0
    }
    
    func deleteByNoteId(noteId: Int64)  throws {
        let blockTable = table.filter(Field_Block.noteId == noteId)
        _ = try db.run(blockTable.delete())
    }
    
    func deleteByParent(parent: Int64)  throws{
        let blockTable = table.filter(Field_Block.parent == parent)
        _ = try db.run(blockTable.delete())
    }
    
    func queryByType(type:String) throws ->[Block] {
        let query = table.filter(Field_Block.type == type).order(Field_Block.sort.asc)
        let blockRows = try db.prepare(query)
        var blocks:[Block] = []
        for row in blockRows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
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
    
    func query(noteId:Int64,type:String) throws ->[Block] {
        let query = table.filter(Field_Block.noteId == noteId && Field_Block.type == type).order(Field_Block.sort.asc)
        let blockRows = try db.prepare(query)
        var blocks:[Block] = []
        for row in blockRows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
    
    func query(boardId:Int64,type:String) throws ->[Block] {
        let selectSQL = """
                            select * from block where note_id in (
                            select section_note.note_id from section_note
                            inner join section on  (section.id = section_note.section_id and section.board_id = \(boardId))
                            ) and type = '\(type)'
                        """
        let stmt = try db.prepare(selectSQL)
        let rows = stmt.typedRows()
        var blocks:[Block] = []
        for row in rows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
    
    
    func deleteByBoardId(boardId:Int64) throws -> Int {
        let deleteSQL = """
                            delete from block where note_id in (
                            select section_note.note_id from section_note
                            inner join section on  (section.id = section_note.section_id and section.board_id = \(boardId))
                            ) or id in (
                                select section_note.note_id from section_note
                                inner join section on  (section.id = section_note.section_id and section.board_id = \(boardId))
                            )
                        """
        try db.run(deleteSQL)
        return db.changes
    }
    
    
    func searchNoteBlocks(keyword: String) throws -> [Block] {
        let selectSQL = """
        select * from block where type = 'note' and (
            id in ( select note_id from block where text like '%\(keyword)%')
            or
            text like '%\(keyword)%'
        )
        """
        let stmt = try db.prepare(selectSQL)
        let rows = stmt.typedRows()
        var blocks:[Block] = []
        for row in rows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
    
    
    func queryNoteBlocksByBoardId(_ boardId:Int64 ,noteBlockStatus: NoteBlockStatus) throws -> [(Int64,Block)] {
        let status = noteBlockStatus.rawValue
        let selectSQL = """
        select b.id, b.type, b.text,section.sort as sort,b.is_checked,b.is_expand,b.source,b.created_at,b.updated_at,
        b.note_id,b.parent,b.status,b.properties,section.section_id
        from block as b
        inner join (
        select section_note.note_id, section_note.sort,section_note.section_id from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = \(boardId))
        ) as section
        on (b.id = section.note_id  and b.status = \(status)) order by b.sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let rows = stmt.typedRows()
        
        var blocks:[(Int64,Block)] = []
        for row in rows {
            let block = generateBlock(row: row)
            let sectionId = row.i64("section_id")!
            blocks.append((sectionId,block))
        }
        
        return blocks
    }
    
    
    func queryNotesCountByBoardId(_ boardId:Int64 ,noteBlockStatus: NoteBlockStatus) throws -> Int64 {
        let status = noteBlockStatus.rawValue
        let selectSQL = """
        select count(*)
        from block as b
        inner join (
        select section_note.note_id, section_note.sort,section_note.section_id from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = \(boardId))
        ) as section
        on (b.id = section.note_id  and b.status = \(status)) order by b.sort asc
        """
        let count = try db.scalar(selectSQL) as! Int64
        return count
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
                    builder.column(Field_Block.updatedAt)
                    builder.column(Field_Block.noteId)
                    builder.column(Field_Block.parent)
                    builder.column(Field_Block.status)
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
                                Field_Block.updatedAt <- block.updatedAt,
                                Field_Block.noteId <- block.noteId,
                                Field_Block.parent <- block.parent,
                                Field_Block.status <- block.status,
                                Field_Block.properties <- block.properties.toJSON()
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
                            Field_Block.updatedAt <- block.updatedAt,
                            Field_Block.noteId <- block.noteId,
                            Field_Block.parent <- block.parent,
                            Field_Block.status <- block.status,
                            Field_Block.properties <- block.properties.toJSON()
        )
        
    }
    
    fileprivate func generateBlock(row: TypedRow) -> Block {
        let id = row.i64("id")!
        let type = row.string("type")!
        let text = row.string("text")!
        let sort = row.double("sort")!
        let isChecked = row.bool("is_checked")
        let isExpand = row.bool("is_expand")
        let source = row.string("source") ?? ""
        let createdAt = row.date("created_at")!
        let updatedAt = row.date("updated_at")!
        
        let noteId = row.i64("note_id")!
        let parent = row.i64("parent")!
        
        let status = row.int("status")!
        
        let properties = row.string("properties") ?? ""
        
        
        let block = Block(id: id, type: type, text: text, isChecked: isChecked, isExpand: isExpand, source: source, createdAt: createdAt, updatedAt: updatedAt, sort: sort, noteId: noteId, parent: parent,status:status, properties: properties.convertToDictionary())
        return block
    }
    
    fileprivate func generateBlock(row: Row) -> Block {
        var block = Block(id: row[Field_Block.id], type: row[Field_Block.type], text: row[Field_Block.text], isChecked: row[Field_Block.isChecked], isExpand: row[Field_Block.isExpand], source: row[Field_Block.source], createdAt: row[Field_Block.createdAt],updatedAt: row[Field_Block.updatedAt],sort: row[Field_Block.sort], noteId: row[Field_Block.noteId],parent:row[Field_Block.parent],status:row[Field_Block.status])
        block.properties = row[Field_Block.properties].convertToDictionary()
        return block
    }
}
