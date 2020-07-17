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
        let insertSql = "INSERT INTO space (id,collect_board_id,board_group_id,category_group_id) VALUES(?,?,?,?)";
        try db.execute(insertSql, args: space.id,space.collectBoardId,space.boardGroupId,space.categoryGroupId)
    }
    
    func query() throws -> Space? {
        let selectSql = "SELECT id,collect_board_id,board_group_id,category_group_id,created_at FROM space"
        let rows = try db.query(selectSql)
        for row in rows {
            let id = row["id"] as! String
            let collectBoardId = row["collect_board_id"] as! String
            let boardGroupId = row["board_group_id"] as! String
            let categoryGroupId = row["category_group_id"] as! String
            
            let createdAt = row["created_at"] as! Date
            
            return Space(id: id, collectBoardId: collectBoardId, boardGroupId: boardGroupId, categoryGroupId: categoryGroupId, createdAt: createdAt)
        }
        return nil
    }
    
    func update(boardGroupIds: [String]) throws {
        let updateSql = "UPDATE space SET board_group_ids = ?"
        try db.execute(updateSql,args: json(from: boardGroupIds)!)
    }
    
}
