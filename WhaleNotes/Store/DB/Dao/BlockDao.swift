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
    static let id = Expression<String>("id")
    static let type = Expression<String>("type")
    static let text = Expression<String>("text")
    static let sort = Expression<Double>("sort")
    static let isChecked = Expression<Bool>("is_checked")
    static let isExpand = Expression<Bool>("is_expand")
    static let source = Expression<String>("source")
    static let createdAt = Expression<Date>("created_at")
    static let updatedAt = Expression<Date>("updated_at")
    static let parentId = Expression<String>("parent_id")
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
    
    func insert( _ block:Block) throws {
       let insertBlock = self.generateBookInsert(block: block)
       try db.run(insertBlock)
    }
    
    
    func updateText(id:String,text:String) throws -> Bool {
        let blockTable = table.filter(Field_Block.id == id)
        let rows = try db.run(blockTable.update(Field_Block.text <- text))
        return rows == 1
    }
    
    
    func updateUpdatedAt(id:String,updatedAt:Date) throws -> Bool {
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
            Field_Block.parentId <- block.parentId,
            Field_Block.status <- block.status,
            Field_Block.updatedAt <- block.updatedAt,
            Field_Block.properties <- block.properties.toJSON()
        ))
        return rows == 1
    }
    
    func updateNoteBlockStatus(boardId: String,status:Int) throws -> Bool {
        let updateSql = """
        update block set status = ?,updated_at = DATE('now') where id in (
        select section_note.noteId from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = ?)
        )
        """
        let stmt = try db.prepare(updateSql)
        try stmt.run(boardId,status)
        return db.changes >= 0
    }
    
    // 递归删除
    func delete(id:String) throws -> Bool {
        let deleteSQL = """
            delete from block where id in (
                with recursive
                b as (
                        select * from block where id = ?
                        union all
                        select block.* from b join block on b.id = block.parent_id
                )
              select id from b
            )
        """
        let stmt = try db.prepare(deleteSQL)
        try stmt.run(id)
        return db.changes > 0
    }
    
    
    func deleteMultiple(noteBlockIds: [String]) throws -> Bool {
        let ids = noteBlockIds.map{return "'\($0)'"}.joined(separator: ",")
        let deleteSQL = """
            delete from block where id in (
                with recursive
                b as (
                        select * from block where id in (\(ids))
                        union all
                        select block.* from b join block on b.id = block.parent_id
                )
              select id from b
            )
        """
        try db.run(deleteSQL)
        return db.changes > 0
    }
    
    
    func delete(noteId:String,type:String) throws -> Bool {
        let deleteSQL = """
            delete from block where id in (
                with recursive
                b as (
                        select * from block where id = ?
                        union all
                        select block.* from b join block on b.id = block.parent_id and block.type = ?
                )
              select id from b where id != ?
            )
        """
        let stmt = try db.prepare(deleteSQL)
        try stmt.run(noteId,type,noteId)
        return db.changes > 0
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
    
    func query(noteId:String) throws ->[Block] {
        let selectSQL = """
                                with recursive
                                b as (
                                        select * from block where id = ?
                                        union all
                                        select block.* from b join block on b.id = block.parent_id
                                )
                              select * from b where parent_id != ""
                        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(noteId).typedRows()
        var blocks:[Block] = []
        for row in rows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
    
    func query(parentId:String,type:String) throws ->[Block] {
        let selectSQL = """
                                with recursive
                                b as (
                                        select * from block where id = ?
                                        union all
                                        select block.* from b join block on b.id = block.parent_id and block.type = ?
                                )
                              select * from b where parent_id != ""  order by sort asc
                        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(parentId).typedRows()
        var blocks:[Block] = []
        for row in rows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
    
    func query(boardId:String,type:String) throws ->[Block] {
        let selectSQL = """
                            select * from block where note_id in (
                            select section_note.note_id from section_note
                            inner join section on  (section.id = section_note.section_id and section.board_id = ? )
                            ) and type = ?
                        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(boardId,type).typedRows()
        var blocks:[Block] = []
        for row in rows {
            let block = generateBlock(row: row)
            blocks.append(block)
        }
        return blocks
    }
    
    
    func deleteByBoardId(boardId:String) throws -> Int {
        let deleteSQL = """
                            delete from block where note_id in (
                            select section_note.note_id from section_note
                            inner join section on  (section.id = section_note.section_id and section.board_id = ?)
                            ) or id in (
                                select section_note.note_id from section_note
                                inner join section on  (section.id = section_note.section_id and section.board_id = ?)
                            )
                        """
        let stmt = try db.prepare(deleteSQL)
        try stmt.run(boardId,boardId)
        return db.changes
    }
    
    func searchNoteBlocks(keyword: String) throws -> [NoteAndBoard] {
        let selectSQL = """
              with recursive
                note_ids as (
                                select block.* from block where text like ?
                                union all
                                select block.* from note_ids join block on note_ids.parent_id = block.id
                ), b as (
                                select block.*,
                                board.id as board_id,board.icon as board_icon,board.title as board_title,board.sort as board_sort,board.category_id as board_category_id,board.type as board_type,board.created_at as board_created_at
                                from block
                                inner join section_note on section_note.note_id = block.id and block.id  in (select id from note_ids)
                                inner join section on section.id = section_note.section_id
                                inner join board on  board.id = section.board_id
                                union all
                                select block.*,
                                0 as board_id, '' as board_icon,'' as board_title,0 as board_sort,'' as board_category_id, 0 as board_type,'' as board_created_at
                                from b
                                join block on b.id = block.parent_id
                )
              select * from b order by sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run("%\(keyword)%").typedRows()
        var blockIdAndBoard:[String:Board] = [:]
        
        var noteBlocks:[Block] = []
        var allChildBlocks:[Block] = []
        for row in rows {
            let block = generateBlock(row: row)
            if block.type == BlockType.note.rawValue {
                noteBlocks.append(block)
                let board = BoardDao.generateBoardByTypeRow(row: row)
                blockIdAndBoard[block.id] = board
            }else {
                allChildBlocks.append(block)
            }
        }
        
        var noteAndBoards:[NoteAndBoard] = []
        
        for noteBlock in noteBlocks {
            var childBlocks:[Block] = []
            getChildBlocksByBlock(blocks: allChildBlocks, childBlocks: &childBlocks, parentBlock: noteBlock)
            
            let note  = Note(rootBlock: noteBlock, childBlocks: childBlocks)
            guard let board = blockIdAndBoard[noteBlock.id] else { continue }
            noteAndBoards.append(NoteAndBoard(note: note, board: board))
        }
        
        return noteAndBoards
    }
    
    
    func getChildBlocksByBlock(blocks:[Block],childBlocks:inout [Block], parentBlock:Block) {
        let tempChildBlocks = blocks.filter { $0.parentId == parentBlock.id }
        if tempChildBlocks.isNotEmpty {
            childBlocks.append(contentsOf: tempChildBlocks)
            for block in tempChildBlocks {
                getChildBlocksByBlock(blocks:blocks,childBlocks:&childBlocks,parentBlock:block)
            }
        }
    }

    
    func querySectionNotes(boardId:String) throws -> [String:[Note]] {
        let selectSQL = """
                with recursive
                b as (
                                select block.*,section.id as section_id from block
                                inner join section_note on section_note.note_id = block.id
                                inner join section on section.id = section_note.section_id and section.board_id = ?
                                union all
                                select block.*, "" as section_id  from b join block on b.id = block.parent_id
                )
               select * from b order by sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(boardId).typedRows()
        
        var blocks:[Block] = []
        
        
        var sectionNotes:[String:[Note]] = [:]
        var noteAndSectionIds:[String:String] = [:]
        
        for row in rows {
            let block = generateBlock(row: row)
            let sectionId = row.string("section_id")!
            
            if sectionId.isNotEmpty {
                noteAndSectionIds[block.id] = sectionId
            }
            blocks.append(block)
        }
        
        let noteBlocks = blocks.filter { $0.type == BlockType.note.rawValue }
        if noteBlocks.isEmpty {
            return sectionNotes
        }

        for noteBlock in noteBlocks {
            var childBlocks:[Block] = []
            getChildBlocksByBlock(blocks:blocks,childBlocks: &childBlocks, parentBlock: noteBlock)
            
            let note = Note(rootBlock: noteBlock, childBlocks: childBlocks)
            if let sectionId = noteAndSectionIds[noteBlock.id] {
                
               var notes =  sectionNotes[sectionId] ?? []
               notes.append(note)
               sectionNotes[sectionId] = notes
            }
            
        }
            
        return sectionNotes
    }
    
    func queryNoteBlocksByBoardId(_ boardId:String ,noteBlockStatus: NoteBlockStatus) throws -> [(String,Block)] {
        let status = noteBlockStatus.rawValue
        let selectSQL = """
        select b.id, b.type, b.text,section.sort as sort,b.is_checked,b.is_expand,b.source,b.created_at,b.updated_at,
        b.parent_id,b.status,b.properties,section.section_id
        from block as b
        inner join (
        select section_note.note_id, section_note.sort,section_note.section_id from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = ?)
        ) as section
        on (b.id = section.note_id  and b.status = ?) order by b.sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(boardId,status).typedRows()
        
        var blocks:[(String,Block)] = []
        for row in rows {
            let block = generateBlock(row: row)
            let sectionId = row.string("section_id")!
            blocks.append((sectionId,block))
        }
        
        return blocks
    }
    
    
    func queryNotesCountByBoardId(_ boardId:String ,noteBlockStatus: NoteBlockStatus) throws -> Int64 {
        let status = noteBlockStatus.rawValue
        let selectSQL = """
        select count(*)
        from block as b
        inner join (
        select section_note.note_id, section_note.sort,section_note.section_id from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = ?)
        ) as section
        on (b.id = section.note_id  and b.status = ?) order by b.sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let count = try stmt.run(boardId,status).scalar() as! Int64
        return count
    }
}


extension BlockDao {
    fileprivate func createTable() -> Table {
        let tableBlock = Table("block")
        
        do {
            try! db.run(
                tableBlock.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Block.id)
                    builder.column(Field_Block.type)
                    builder.column(Field_Block.text)
                    builder.column(Field_Block.sort)
                    builder.column(Field_Block.isChecked)
                    builder.column(Field_Block.isExpand)
                    builder.column(Field_Block.source)
                    builder.column(Field_Block.createdAt)
                    builder.column(Field_Block.updatedAt)
                    builder.column(Field_Block.parentId)
                    builder.column(Field_Block.status)
                    builder.column(Field_Block.properties)
                })
            )
        }
        return tableBlock
    }
    
    
    func generateBookInsert(block: Block,conflict:OnConflict = OnConflict.fail) -> Insert {
        
        
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
                                Field_Block.parentId <- block.parentId,
                                Field_Block.status <- block.status,
                                Field_Block.properties <- block.properties.toJSON()
            )
        
    }
    
    fileprivate func generateBlock(row: TypedRow) -> Block {
        let id = row.string("id")!
        let type = row.string("type")!
        let text = row.string("text")!
        let sort = row.double("sort")!
        let isChecked = row.bool("is_checked")
        let isExpand = row.bool("is_expand")
        let source = row.string("source") ?? ""
        let createdAt = row.date("created_at")!
        let updatedAt = row.date("updated_at")!
        
        let parentId = row.string("parent_id")!
        let status = row.int("status")!
        let properties = row.string("properties") ?? ""
        
        
        let block = Block(id: id, type: type, text: text, isChecked: isChecked, isExpand: isExpand, source: source, createdAt: createdAt, updatedAt: updatedAt, sort: sort, parentId: parentId,status:status, properties: properties.convertToDictionary())
        return block
    }
    
    fileprivate func generateBlock(row: Row) -> Block {
        var block = Block(id: row[Field_Block.id], type: row[Field_Block.type], text: row[Field_Block.text], isChecked: row[Field_Block.isChecked], isExpand: row[Field_Block.isExpand], source: row[Field_Block.source], createdAt: row[Field_Block.createdAt],updatedAt: row[Field_Block.updatedAt],sort: row[Field_Block.sort],parentId:row[Field_Block.parentId],status:row[Field_Block.status])
        block.properties = row[Field_Block.properties].convertToDictionary()
        return block
    }
}
