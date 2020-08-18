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
    
}

extension BlockDao {
    func insert( _ block:Block) throws {
        let insertSQL = "insert into block(id,type,title,status,properties) values(?,?,?,?,?)"
        try db.execute(insertSQL, args: block.id,block.type.rawValue,block.title,block.status.rawValue,block.propertiesJSON)
    }
    
    func update(_ block:Block) throws {
        let updateSQL = "update block set type = ?,title=?,status=?,properties = ?,updated_at=datetime('now') where id = ?"
        try db.execute(updateSQL, args:block.type.rawValue,block.title,block.status.rawValue,block.propertiesJSON,block.id)
    }
    
    func updateUpdatedAt(id:String) throws {
        let updateSQL = " update block set updated_at = datetime('now') where id = ?"
        try db.execute(updateSQL, args:id)
    }
    
    
    func update(blockId:String,properties:String) throws {
        let updateSQL = "update block set properties = ?,updated_at=datetime('now') where id = ?"
        try db.execute(updateSQL,args:properties,blockId)
    }
    
    func delete(_ id:String) throws {
        
    }
    
    func query(id:String) throws -> BlockInfo {
        return BlockInfo(block: Block())
    }
    
    
    func query(ownerId:String,type:String,status:Int = BlockStatus.normal.rawValue) throws ->[BlockInfo] {
        
        let typeSql = type.isNotEmpty ? "and block.type = '\(type)'" : ""
        
        let selectSQL = """
                     with recursive
                        b as (
                                select block_t.*,
                                IFNULL(block_position.id,'') as position_id, IFNULL(block_position.owner_id,'') as owner_id, IFNULL(block_position.position,0) as position
                                from  (
                                    select * from block where block.status = ? \(typeSql)
                                ) as block_t
                                join block_position on block_position.block_id = block_t.id and block_position.owner_id = ?
                                union all
                                select block.*,
                                block_position.id as position_id,block_position.owner_id,block_position.position as position
                                from b
                                join block_position on block_position.owner_id = b.id
                                join block on block.id =  block_position.block_id and block.status = ? \(typeSql)

                        )
                      select * from b where id != ? order by position;
                    """
        let rows = try db.query(selectSQL, args: status,ownerId,status,ownerId)
        let blockInfos:[BlockInfo] = extract(rows: rows)
        return blockInfos
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
        var title = (row["title"] as? String) ?? ""
        let status = BlockStatus.init(rawValue:  row["status"] as! Int)!
        let propertiesJSON = row["properties"] as! String
        
        var properties = convertProperties(json: propertiesJSON, blockType: type)
        
        let createdAt = row["created_at"] as! Date
        let updatedAt = row["updated_at"] as! Date
        
        if type == .board {
            var boardProperty =  properties as! BlockBoardProperty
            if boardProperty.type == .collect {
                boardProperty.icon = "tray.full"
                title = "收集板"
                properties = boardProperty
            }
        }
        
        let block = Block(id: id, title: title, type: type, status: status, properties: properties, createdAt: createdAt, updatedAt: updatedAt)
        
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
        case .todo:
            return json2Object(json, type: BlockTodoProperty.self)!
        case .image:
            return json2Object(json, type: BlockImageProperty.self)!
        case .bookmark:
            return json2Object(json, type: BlockBookmarkProperty.self)!
        case .todo_list:
            return json2Object(json, type: BlockTodoListProperty.self)!
        case .board:
            return json2Object(json, type: BlockBoardProperty.self)!
        }
        
    }
}
