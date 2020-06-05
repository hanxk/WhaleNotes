//
//  BoardCategoryDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/5.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

fileprivate enum Field_BoardCategory{
    static let id = Expression<Int64>("id")
    static let title = Expression<String>("title")
    static let sort = Expression<Double>("sort")
    static let createdAt = Expression<Date>("created_at")
}

class BoardCategoryDao {
    
    private var table: Table!
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        table = self.createTable()
    }
    
    func insert( _ boardCategory:BoardCategory) throws -> Int64 {
        let insertBoard = self.generateInsert(boardCategory: boardCategory,conflict: .ignore)
        let rowId = try db.run(insertBoard)
        return rowId
    }
    
    func delete(id: Int64)  throws -> Bool {
        let boardData = table.filter(Field_BoardCategory.id == id)
        let rows = try db.run(boardData.delete())
        return rows > 0
    }
    
    func queryAll() throws ->[BoardCategory] {
        let rows = try db
            .prepare(table.order(Field_BoardCategory.sort.asc))
        var boards:[BoardCategory] = []
        for row in rows {
            let boardCategory = generateBoardCategory(row: row)
            boards.append(boardCategory)
        }
        return boards
    }
    
}


extension BoardCategoryDao {
    fileprivate func createTable() -> Table {
        let table = Table("board_category")
        
        do {
            try! db.run(
                table.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_BoardCategory.id,primaryKey: .autoincrement)
                    builder.column(Field_BoardCategory.title)
                    builder.column(Field_BoardCategory.sort)
                    builder.column(Field_BoardCategory.createdAt)
                })
            )
        }
        return table
    }
    
    
    fileprivate func generateInsert(boardCategory: BoardCategory,conflict:OnConflict = OnConflict.fail) -> Insert {
        if boardCategory.id > 0 {
            return table.insert(or: conflict,
                                Field_BoardCategory.id <- boardCategory.id,
                                Field_BoardCategory.title <- boardCategory.title,
                                Field_BoardCategory.sort <- boardCategory.sort,
                                Field_BoardCategory.createdAt <- boardCategory.createdAt
            )
        }
        return table.insert(or: conflict,
                                Field_BoardCategory.title <- boardCategory.title,
                                Field_BoardCategory.sort <- boardCategory.sort,
                                Field_BoardCategory.createdAt <- boardCategory.createdAt
        )
    }
    
    fileprivate func generateBoardCategory(row: Row) -> BoardCategory {
        let boardCategory = BoardCategory(id: row[Field_BoardCategory.id],  title: row[Field_BoardCategory.title], sort: row[Field_BoardCategory.sort], createdAt: row[Field_BoardCategory.createdAt])
        return boardCategory
    }
}
