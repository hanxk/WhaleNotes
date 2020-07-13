//
//  SpaceDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
class SpaceDao {
    private  var db: SQLiteDatabase!
    init(dbCon: SQLiteDatabase) {
        db = dbCon
    }
}

extension SpaceDao {
    func insert(space:Space) throws {
        let insertSql = "INSERT INTO space (id,collect_board_id,board_group_ids) VALUES(?,?,?)";
        try db.execute(insertSql, args: space.id,space.collectBoardId,json(from: space.boardGroupIds)!)
    }
    
    func query() throws -> Space? {
        let selectSql = "SELECT id,collect_board_id,board_group_ids,created_at FROM space"
        let rows = try db.query(selectSql)
        for row in rows {
            let id = row["id"] as! String
            let collectBoardId = row["collect_board_id"] as! String
            
            let json =  row["board_group_ids"] as! String
            let boardGroupIds = json2Object(json, type: [String].self)!
            
            let createdAt = (row["created_at"] as! Double)
            return Space(id: id, collectBoardId: collectBoardId, boardGroupIds: boardGroupIds, createdAt: Date(timeIntervalSince1970: createdAt))
        }
        return nil
    }
    
    func update(boardGroupIds: [String]) throws {
        let updateSql = "UPDATE space SET board_group_ids = ?"
        try db.execute(updateSql,args: json(from: boardGroupIds)!)
    }
    
}
