//
//  BlockPositionDap.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/13.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
class BlockPositionDao {
    private  var db: SQLiteDatabase!
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
}

extension BlockPositionDao {
    
    func insert(_ blockPosition:BlockPosition) throws {
        let insertSql = "INSERT INTO block_position (id,block_id, owner_id,position) VALUES(?,?,?,?)";
        try db.execute(insertSql, args: blockPosition.id,blockPosition.blockId,blockPosition.ownerId,blockPosition.position)
    }
    
    func queryMinPosition(id:String) throws -> BlockPosition? {
        let selectSql = "SELECT id,block_id, owner_id,position FROM block_position WHERE owner_id = ? order by position limit 1"
        let rows = try db.query(selectSql,args: id)
        for row in rows {
            return self.extract(row: row)
        }
        return nil
    }
    
    func query(id:String) throws -> BlockPosition? {
        let selectSql = "SELECT id,block_id, owner_id,position FROM block_position WHERE id = ?"
        let rows = try db.query(selectSql,args: id)
        for row in rows {
            return self.extract(row: row)
        }
        return nil
    }
    
    func update(_ blockPosition:BlockPosition) throws {
        let updateSql = "UPDATE block_position SET block_id = ? , owner_id = ? ,position = ? WHERE id = ?"
        try db.execute(updateSql,args: blockPosition.blockId,blockPosition.ownerId,blockPosition.position,blockPosition.id)
    }
    
    func delete(_ id:String) throws{
        let insertSql = "DELETE FROM block_position WHERE id = ?";
        try db.execute(insertSql, args:id)
    }
    
    func delete(blockId:String,includeChild:Bool = false) throws {
        var deleteSql:String
        if includeChild {
            deleteSql = """
                delete from block_position where block_id in (
                    with recursive
                    b as (
                            select id from block where id = ?
                            union all
                            select block.id from b join block on b.id = block.parent_id
                    )
                   select id from b
                )
            """
        }else {
            deleteSql = "DELETE FROM block_position WHERE block_id = ?"
        }
        try db.execute(deleteSql, args: blockId)
    }
    
    
    func delete(noteStatus:NoteBlockStatus) throws {
        let deleteSQL = """
                        with recursive
                        b as (
                            select block.id from block
                            where type = 'note' and json_extract(block.properties,'$.status') = ?
                            union all
                            select block_position.block_id as id from b
                            join block_position on block_position.owner_id = b.id
                        )
                      delete from block_position where block_id in (select id from b);
                    """
        try db.execute(deleteSQL,args: noteStatus.rawValue)
    }
    
    
    func delete(ownerId:String) throws{
        let deleteSql = "DELETE FROM block_position WHERE owner_id = ?";
        try db.execute(deleteSql, args:ownerId)
    }
    
    func delete(blockId:String) throws{
        let deleteSql = "DELETE FROM block_position WHERE block_id = ?";
        try db.execute(deleteSql, args:blockId)
    }
    
    private func extract(row:Row) -> BlockPosition {
        let id = row["id"] as! String
        let blockId = row["block_id"] as! String
        let parentId =  row["owner_id"] as! String
        let position = (row["position"] as! Double)
        return BlockPosition(id: id, blockId: blockId, ownerId: parentId, position: position)
    }
    
}