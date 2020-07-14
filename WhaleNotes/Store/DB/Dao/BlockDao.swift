//
//  BlockDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

class BlockDao {
    
    private  var db: SQLiteDatabase!
    
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
    
    
    
    
    
    
    func deleteMultiple(noteBlockIds: [String]) throws -> Int {
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
        try db.execute(deleteSQL)
        return 1
    }
    
    
    func delete(noteId:String,type:String) throws -> Int {
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
        try db.execute(deleteSQL, args: noteId,type,noteId)
        return 1
    }
    
    func queryByType(type:String) throws ->[Block] {
        //        let selectSQL = "select * from block order by sort where type = ?"
        //        let stmt = try db.prepare(selectSQL)
        //        let rows = try stmt.run(type).typedRows()
        //        var blocks:[Block] = []
        //        for row in rows {
        //            let block = generateBlock(row: row)
        //            blocks.append(block)
        //        }
        //        return blocks
        return []
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
        //        let stmt = try db.prepare(selectSQL)
        //        let rows = try stmt.run(noteId).typedRows()
        //        var blocks:[Block] = []
        //        for row in rows {
        //            let block = generateBlock(row: row)
        //            blocks.append(block)
        //        }
        //        return blocks
        return []
    }
    
    
    func query(boardId:String,type:String) throws ->[Block] {
        let selectSQL = """
                            select * from block where note_id in (
                            select section_note.note_id from section_note
                            inner join section on  (section.id = section_note.section_id and section.board_id = ? )
                            ) and type = ?
                        """
        //        let stmt = try db.prepare(selectSQL)
        //        let rows = try stmt.run(boardId,type).typedRows()
        //        var blocks:[Block] = []
        //        for row in rows {
        //            let block = generateBlock(row: row)
        //            blocks.append(block)
        //        }
        //        return blocks
        return []
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
        //        let stmt = try db.prepare(deleteSQL)
        //        try stmt.run(boardId,boardId)
        //        return db.changes
        return 1
    }
    
    //    func searchNoteBlocks(keyword: String) throws -> [NoteAndBoard] {
    //        let selectSQL = """
    //              with recursive
    //                note_ids as (
    //                                select block.* from block where json_extract(block.properties, '$.title') like ?
    //                                union all
    //                                select block.* from note_ids join block on note_ids.parent_id = block.id
    //                ), b as (
    //                                select block.*,
    //                                board.id as board_id,board.icon as board_icon,board.title as board_title,board.sort as board_sort,board.category_id as board_category_id,board.type as board_type,board.created_at as board_created_at
    //                                from block
    //                                inner join section_note on section_note.note_id = block.id and block.id  in (select id from note_ids)
    //                                inner join section on section.id = section_note.section_id
    //                                inner join board on  board.id = section.board_id
    //                                union all
    //                                select block.*,
    //                                0 as board_id, '' as board_icon,'' as board_title,0 as board_sort,'' as board_category_id, 0 as board_type,'' as board_created_at
    //                                from b
    //                                join block on b.id = block.parent_id
    //                )
    //              select * from b order by sort asc
    //        """
    //        let stmt = try db.prepare(selectSQL)
    //        let rows = try stmt.run("%\(keyword)%").typedRows()
    //        var blockIdAndBoard:[String:Board] = [:]
    //
    //        var noteBlocks:[Block] = []
    //        var allChildBlocks:[Block] = []
    //        for row in rows {
    //            let block = generateBlock(row: row)
    //            if block.type == BlockType.note.rawValue {
    //                noteBlocks.append(block)
    //                let board = BoardDao.generateBoardByTypeRow(row: row)
    //                blockIdAndBoard[block.id] = board
    //            }else {
    //                allChildBlocks.append(block)
    //            }
    //        }
    //
    //        var noteAndBoards:[NoteAndBoard] = []
    //
    //        for noteBlock in noteBlocks {
    //            var childBlocks:[Block] = []
    //            getChildBlocksByBlock(blocks: allChildBlocks, childBlocks: &childBlocks, parentBlock: noteBlock)
    //
    //            let note  = Note(rootBlock: noteBlock, childBlocks: childBlocks)
    //            guard let board = blockIdAndBoard[noteBlock.id] else { continue }
    //            noteAndBoards.append(NoteAndBoard(note: note, board: board))
    //        }
    //
    //        return []
    //    }
    //
    
    
    
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
        //        let stmt = try db.prepare(selectSQL)
        //        let rows = try stmt.run(noteBlockStatus.rawValue,boardId).typedRows()
        //
        //        var blocks:[Block] = []
        //
        //
        //        var sectionNotes:[String:[Note]] = [:]
        //        var noteAndSectionIds:[String:String] = [:]
        //
        //        for row in rows {
        //            let block = generateBlock(row: row)
        //            let sectionId = row.string("section_id")!
        //
        //            if sectionId.isNotEmpty {
        //                noteAndSectionIds[block.id] = sectionId
        //            }
        //            blocks.append(block)
        //        }
        //
        //        let noteBlocks = blocks.filter { $0.type == BlockType.note.rawValue }
        //        if noteBlocks.isEmpty {
        //            return sectionNotes
        //        }
        //
        //        for noteBlock in noteBlocks {
        //            var childBlocks:[Block] = []
        //            getChildBlocksByBlock(blocks:blocks,childBlocks: &childBlocks, parentBlock: noteBlock)
        //
        //            let note = Note(rootBlock: noteBlock, childBlocks: childBlocks)
        //            if let sectionId = noteAndSectionIds[noteBlock.id] {
        //
        //               var notes =  sectionNotes[sectionId] ?? []
        //               notes.append(note)
        //               sectionNotes[sectionId] = notes
        //            }
        //
        //        }
        
        return [:]
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
        //        let stmt = try db.prepare(selectSQL)
        //        let rows = try stmt.run(boardId,status).typedRows()
        //
        //        var blocks:[(String,Block)] = []
        //        for row in rows {
        //            let block = generateBlock(row: row)
        //            let sectionId = row.string("section_id")!
        //            blocks.append((sectionId,block))
        //        }
        //
        return []
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
        //        let stmt = try db.prepare(selectSQL)
        //        let count = try stmt.run(boardId,status).scalar() as! Int64
        //        return count
        return 1
    }
}


extension BlockDao {
    
    //    fileprivate func generateBlock(row: TypedRow) -> Block {
    //        let id = row.string("id")!
    //        let type = row.string("type")!
    //        let properties = row.string("properties") ?? ""
    //        let parentId = row.string("parent_id")!
    //        let sort = row.double("sort")!
    //        let createdAt = row.date("created_at")!
    //        let updatedAt = row.date("updated_at")!
    //
    //        let block = Block(id: id, type: type, properties: self.convertProperties(json: properties, type: type), parentId: parentId, sort: sort, createdAt: createdAt, updatedAt: updatedAt)
    //        return block
    //    }
    //
    
}



extension BlockDao {
    
    func insert( _ block:Block) throws {
        let insertSQL = "insert into block(id,type,properties,content,parent_id,parent_table,created_at,updated_at) values(?,?,?,?,?,?,?,?)"
        
        
        try db.execute(insertSQL, args: block.id,block.type.rawValue,block.propertiesJSON,block.contentJSON,block.parentId,block.parentTable.rawValue,
                       block.createdAt.timeIntervalSince1970,
                       block.updatedAt.timeIntervalSince1970)
    }
    
    
    func updateUpdatedAt(id:String,updatedAt:Date) throws {
        let updateSQL = " update block set updated_at = ? where id = ?"
        try db.execute(updateSQL, args: updatedAt.toSQLDateString(),id)
    }
    
    
    func updateBlock(block:Block) throws {
        let updateSQL = "update block set type = ?,properties = ?,content = ?,parent_id = ?,parent_table = ?,updated_at=? where id = ?"
        try db.execute(updateSQL, args:block.type.rawValue,block.propertiesJSON,block.contentJSON,block.parentId,block.parentTable.rawValue,block.updatedAt.timeIntervalSince1970,block.id)
    }
    
    func updateBlockParentId(oldParentId:String,newParentId:String) throws {
        let updateSQL = "update block set parent_id = ?,updated_at=CURRENT_TIMESTAMP where parent_id = ?"
        try db.execute(updateSQL, args:newParentId,oldParentId)
    }
    
    
    func updateProperties(id:String,propertiesJSON:String) throws {
        let updateSQL = "update block set properties = ?,updated_at=CURRENT_TIMESTAMP where id = ?"
        try db.execute(updateSQL, args:propertiesJSON,id)
    }
    
    func updateContent(id:String,content:[String]) throws {
        let updateSQL = "update block set content = ?,updated_at=CURRENT_TIMESTAMP where id = ?"
        try db.execute(updateSQL, args:json(from: content)!,id)
    }
    
    func query(id: String) throws -> Block? {
        let selectSql = "SELECT * FROM block WHERE id = ?"
        let rows = try db.query(selectSql, args: id)
        if rows.isEmpty {
            return nil
        }
        return extract(row: rows[0])
    }
    
    
    func queryChilds(id:String) throws ->[BlockInfo] {
        let selectSQL = """
                              with recursive
                                b as (
                                        select block.*,
                                        '' as position_id,'' as owner_id,0 as position
                                        from block where parent_id = ?
                                        union all
                                        select block.*,
                                        block_position.id as position_id,block_position.owner_id,block_position.position as position
                                        from b
                                        join block_position on block_position.owner_id = b.id
                                        join block on block.id =  block_position.block_id
                                        
                                )
                              select * from b;
                        """
        let rows = try db.query(selectSQL, args: id)
        let blockInfos:[BlockInfo] = extract(rows: rows)
        
        var topLevelBlockInfos:[BlockInfo] = blockInfos.filter {$0.block.parentId == id}
        
        for i in 0..<topLevelBlockInfos.count {
            var childBlockInfos:[BlockInfo] = []
            getChildBlocksByBlock(blocks: blockInfos, childBlocks: &childBlockInfos, parentBlock: topLevelBlockInfos[i])
            topLevelBlockInfos[i].contentBlocks.append(contentsOf: childBlockInfos)
        }
        
        return topLevelBlockInfos
    }
    
    
    func getChildBlocksByBlock(blocks:[BlockInfo],childBlocks:inout [BlockInfo], parentBlock:BlockInfo) {
        var tempChildBlocks = blocks.filter { $0.ownerId == parentBlock.id }
        if tempChildBlocks.isNotEmpty {
            for i in 0..<tempChildBlocks.count {
                var childBlockInfos:[BlockInfo] = []
                getChildBlocksByBlock(blocks:blocks,childBlocks:&childBlockInfos,parentBlock:tempChildBlocks[i])
                tempChildBlocks[i].contentBlocks.append(contentsOf: childBlockInfos)
            }
            tempChildBlocks.sort { $0.blockPosition.position <  $1.blockPosition.position}
            childBlocks.append(contentsOf: tempChildBlocks)
        }
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
    
    
    func query(parentId:String) throws ->[Block] {
        let selectSQL = """
                              with recursive
                                b as (
                                        select block.*,
                                        '' as position_id,'' as owner_id,0 as position
                                        from block where id = ?
                                        union all
                                        select block.*,
                                        block_position.id as position_id,block_position.owner_id,block_position.position
                                        from b
                                        join block_position on block_position.parent_id = b.id
                                        join block on block.id =  block_position.block_id
                                        
                                )
                              select * from b;
                        """
        //        let selectSQL = """
        //                                with recursive
        //                                b as (
        //                                        select * from block where parent_id = ?
        //                                        union all
        //                                        select block.* from b join block on b.id = block.parent_id
        //                                )
        //                              select * from b
        //                        """
        let rows = try db.query(selectSQL, args: parentId)
        return extract(rows: rows)
    }
    
    
    func queryContent(content:[String]) throws ->[Block] {
        let ids = content.map{return "'\($0)'"}.joined(separator: ",")
        let selectSQL = """
                                with recursive
                                b as (
                                        select * from block where id in (\(ids))
                                        union all
                                        select block.* from b join block on b.id = block.parent_id
                                )
                              select * from b
                        """
        let rows = try db.query(selectSQL)
        return extract(rows: rows)
    }
    
    
    func delete(id:String,includeChild:Bool) throws {
        
        var deleteSql:String
        if includeChild {
            deleteSql = """
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
        }else {
            deleteSql = "delete from block where id = ?"
        }
        try db.execute(deleteSql, args: id)
    }
    
}



extension BlockDao {
    
    fileprivate func extract(rows: [Row]) -> [Block] {
        var blocks:[Block] = []
        for row in rows {
            blocks.append(extract(row: row))
        }
        return blocks
    }
    
    fileprivate func extract(rows: [Row]) -> [BlockInfo] {
        var blocks:[BlockInfo] = []
        for row in rows {
            blocks.append(extract(row: row))
        }
        return blocks
    }
    
    
    fileprivate func extract(row: Row) -> Block {
        
        let id = row["id"] as! String
        let type = BlockType.init(rawValue:  row["type"] as! String)!
        
        let propertiesJSON = row["properties"] as! String
        let properties = convertProperties(json: propertiesJSON, blockType: type)
        
        let content = json2Object(row["content"] as! String, type: [String].self)!
        let parentId = row["parent_id"] as! String
        let parentTable = TableType.init(rawValue: row["parent_table"] as! String)!
        let createdAt = Date(timeIntervalSince1970: row["created_at"] as! Double)
        let updatedAt = Date(timeIntervalSince1970: row["updated_at"] as! Double)
        
        
        let block = Block(id: id, type: type, properties: properties, content: content, parentId: parentId, parentTable: parentTable, createdAt: createdAt, updatedAt: updatedAt)
        
        if let boardType =  block.blockBoardProperties?.type,boardType == .collect {
            return Block.convert2LocalSystemBoard(board: block)
        }
        return block
    }
    
    
    fileprivate func extract(row: Row) -> BlockInfo {
        
        let block:Block = self.extract(row: row)
        
        
        let positionId = row["position_id"] as! String
        let ownerId = row["owner_id"] as! String
        let position = row["position"] as! Double
        
        let blockPosition = BlockPosition(id: positionId, blockId: block.id, ownerId: ownerId, position: position)
        
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    
    fileprivate func convertProperties(json:String,blockType:BlockType) -> Any {
        switch blockType {
        case .note:
            return json2Object(json, type: BlockNoteProperty.self)!
        case .text:
            return json2Object(json, type: BlockTextProperty.self)!
        case .todo:
            return json2Object(json, type: BlockTodoProperty.self)!
        case .image:
            return json2Object(json, type: BlockImageProperty.self)!
        case .bookmark:
            return json2Object(json, type: BlockBookmarkProperty.self)!
        case .board:
            return json2Object(json, type: BlockBoardProperty.self)!
        case .toggle:
            return json2Object(json, type: BlockToggleProperty.self)!
        }
        
    }
}
