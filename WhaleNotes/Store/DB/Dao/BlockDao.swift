//
//  BlockDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

//fileprivate enum Field_Block{
//    static let id = Expression<String>("id")
//    static let type = Expression<String>("type")
//    static let text = Expression<String>("text")
//    static let sort = Expression<Double>("sort")
//    static let isChecked = Expression<Bool>("is_checked")
//    static let isExpand = Expression<Bool>("is_expand")
//    static let source = Expression<String>("source")
//    static let createdAt = Expression<Date>("created_at")
//    static let updatedAt = Expression<Date>("updated_at")
//    static let parentId = Expression<String>("parent_id")
//    static let status = Expression<Int>("status")
//    static let properties = Expression<String>("properties")
//
//}

class BlockDao {
    
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        self.createTable()
    }
    
    func insert( _ block:Block) throws {
        let insertSQL = "insert into block(id,type,properties,parent_id,sort,created_at,updated_at) values(?,?,?,?,?,?,?)"
        let stmt = try db.prepare(insertSQL)
        try stmt.run(block.id,block.type,block.propertyJSON,block.parentId,block.sort,
                     block.createdAt.toSQLDateString(),
                     block.updatedAt.toSQLDateString())
    }
    
    
    func updateUpdatedAt(id:String,updatedAt:Date) throws -> Bool {
        let updateSQL = """
           update block set updated_at = ? where id = ?
        """
        let stmt = try db.prepare(updateSQL)
        try stmt.run(updatedAt.toSQLDateString(),id)
        return db.changes > 0
    }
    
    
    func updateBlock(block:Block) throws -> Bool {
        let updateSQL = "update block set type = ?,properties = ?,parent_id = ?,sort = ?,updated_at = ? where id = ?"
        let stmt = try db.prepare(updateSQL)
        try stmt.run(block.type,block.propertyJSON,block.parentId,block.sort,
                     block.updatedAt.toSQLDateString(),block.id)
        return db.changes > 0
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
        let selectSQL = "select * from block order by sort where type = ?"
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(type).typedRows()
        var blocks:[Block] = []
        for row in rows {
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
                                select block.* from block where json_extract(block.properties, '$.title') like ?
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

    
    func querySectionNotes(boardId:String,noteBlockStatus: NoteBlockStatus) throws -> [String:[Note]] {
        let selectSQL = """
                with recursive
                b as (
                                select block.*,section.id as section_id from block
                                inner join section_note on section_note.note_id = block.id and json_extract(block.properties, '$.status') = ?
                                inner join section on section.id = section_note.section_id and section.board_id = ?
                                union all
                                select block.*, "" as section_id  from b join block on b.id = block.parent_id
                )
               select * from b order by sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let rows = try stmt.run(noteBlockStatus.rawValue,boardId).typedRows()
        
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
        select b.id, b.type,b.properties,b.parent_id,section.sort as sort,b.created_at,b.updated_at,
        section.section_id
        from block as b
        inner join (
        select section_note.note_id, section_note.sort,section_note.section_id from section_note
        inner join section on (section.id = section_note.section_id and section.board_id = ?)
        ) as section
        on (b.id = section.note_id and json_extract(b.properties, '$.status') = ?) order by b.sort asc
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
        on (b.id = section.note_id  and json_extract(b.properties, '$.status') = ?) order by b.sort asc
        """
        let stmt = try db.prepare(selectSQL)
        let count = try stmt.run(boardId,status).scalar() as! Int64
        return count
    }
}


extension BlockDao {
    fileprivate func createTable(){
        
        let createSQL = """
                    CREATE TABLE IF NOT EXISTS "block" (
                      "id" TEXT UNIQUE NOT NULL,
                      "type" TEXT NOT NULL,
                      "properties" JSON NOT NULL,
                      "parent_id" TEXT NOT NULL,
                      "sort" REAL NOT NULL,
                      "created_at" TEXT NOT NULL,
                      "updated_at" TEXT NOT NULL
                    );
        """
        
        do {
            try! db.run(createSQL)
        }
    }
    
    
    fileprivate func generateBlock(row: TypedRow) -> Block {
        let id = row.string("id")!
        let type = row.string("type")!
        let properties = row.string("properties") ?? ""
        let parentId = row.string("parent_id")!
        let sort = row.double("sort")!
        let createdAt = row.date("created_at")!
        let updatedAt = row.date("updated_at")!
        
        let block = Block(id: id, type: type, properties: self.convertProperties(json: properties, type: type), parentId: parentId, sort: sort, createdAt: createdAt, updatedAt: updatedAt)
        return block
    }
    
    private func convertProperties(json:String,type:String) -> Any {
        let blockType = BlockType.init(rawValue: type)!
        switch blockType {
        case .note:
            return BlockNoteProperty.toStruct(json: json)
        case .text:
            return BlockTextProperty.toStruct(json: json)
        case .todo:
            return BlockTodoProperty.toStruct(json: json)
        case .image:
            return BlockImageProperty.toStruct(json: json)
        case .bookmark:
            return BlockBookmarkProperty.toStruct(json: json)
        }
    }
}
