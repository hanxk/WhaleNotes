//
//  SectionsDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

fileprivate enum Field_Board{
    static let id = Expression<Int64>("id")
    static let icon = Expression<String>("icon")
    static let title = Expression<String>("title")
    static let sort = Expression<Double>("sort")
    static let categoryId = Expression<Int64>("category_id")
    static let type = Expression<Int>("type")
    static let createdAt = Expression<Date>("created_at")
}

class BoardDao {
    
    private var table: Table!
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        table = self.createTable()
    }
    
    func insert( _ board:Board) throws -> Int64 {
        let insertBoard = self.generateBoardInsert(board: board,conflict: .ignore)
        let rowId = try db.run(insertBoard)
        return rowId
    }
    
    func delete(id: Int64)  throws -> Bool {
        let boardData = table.filter(Field_Board.id == id)
        let rows = try db.run(boardData.delete())
        return rows > 0
    }
    
    
    func updateBoard(_ board:Board)  throws -> Bool {
        let boardData = table.filter(Field_Board.id == board.id)
        let rows = try db.run(boardData.update( Field_Board.icon <- board.icon,
                                    Field_Board.title <- board.title,
                                    Field_Board.sort <- board.sort,
                                    Field_Board.categoryId <- board.categoryId,
                                    Field_Board.type <- board.type
                                    ))
        return rows == 1
    }
    
    
    func updateCategoryId(id: Int64,categoryId:Int64)  throws -> Bool {
        let boardData = table.filter(Field_Board.id == id)
        let rows = try db.run(boardData.update(
                                                Field_Board.categoryId <- categoryId
                                              ))
        return rows == 1
    }
    
    func queryAll(categoryId:Int64,type:Int = 1) throws ->[Board] {
        let query = table.filter(Field_Board.categoryId == categoryId && Field_Board.type == type).order(Field_Board.sort.asc)
        let rows = try db.prepare(query)
        var boards:[Board] = []
        for row in rows {
            let board = generateBoard(row: row)
            boards.append(board)
        }
        return boards
    }
    
}


extension BoardDao {
    fileprivate func createTable() -> Table {
        let table = Table("board")
        
        do {
            try! db.run(
                table.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Board.id,primaryKey: .autoincrement)
                    builder.column(Field_Board.icon)
                    builder.column(Field_Board.title)
                    builder.column(Field_Board.sort)
                    builder.column(Field_Board.categoryId)
                    builder.column(Field_Board.type)
                    builder.column(Field_Board.createdAt)
                })
            )
        }
        return table
    }
    
    
    
    
    fileprivate func generateBoardInsert(board: Board,conflict:OnConflict = OnConflict.fail) -> Insert {
        if board.id > 0 {
            return table.insert(or: conflict,
                                Field_Board.id <- board.id,
                                Field_Board.icon <- board.icon,
                                Field_Board.title <- board.title,
                                Field_Board.sort <- board.sort,
                                Field_Board.categoryId <- board.categoryId,
                                Field_Board.type <- board.type
            )
        }
        return table.insert(or: conflict,
                                Field_Board.icon <- board.icon,
                                Field_Board.title <- board.title,
                                Field_Board.sort <- board.sort,
                                Field_Board.categoryId <- board.categoryId,
                                Field_Board.type <- board.type,
                                Field_Board.createdAt <- board.createdAt
        )
    }
    
    fileprivate func generateBoard(row: Row) -> Board {
        let board = Board(id: row[Field_Board.id], icon: row[Field_Board.icon], title: row[Field_Board.title], sort: row[Field_Board.sort], categoryId:  row[Field_Board.categoryId],type:row[Field_Board.type] ,createdAt: row[Field_Board.createdAt])
        return board
    }
}
