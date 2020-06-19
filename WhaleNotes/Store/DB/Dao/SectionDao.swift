//
//  BoardsDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

enum Field_Section{
    static let id = Expression<Int64>("id")
    static let title = Expression<String>("title")
    static let sort = Expression<Double>("sort")
    static let boardId = Expression<Int64>("board_id")
    static let createdAt = Expression<Date>("created_at")
}

class SectionDao {
    
    private(set) var table: Table!
    private  var db: Connection!
    
    init(dbCon: Connection) {
        db = dbCon
        table = self.createTable()
    }
    
    func insert( _ section:Section) throws -> Int64 {
        let insertSection = self.generateSectionInsert(section: section,conflict: .ignore)
        let rowId = try db.run(insertSection)
        return rowId
    }
    
    func delete(id: Int64)  throws -> Bool {
        let sectionData = table.filter(Field_Section.id == id)
        let rows = try db.run(sectionData.delete())
        return rows > 0
    }
    
    func query(boardId:Int64) throws -> [Section] {
        var sections:[Section] = []
        let query = table.filter(Field_Section.boardId == boardId).order(Field_Section.sort.asc)
        let rows = try db.prepare(query)
        for row in rows {
            let section = generateSection(row: row)
            sections.append(section)
        }
        return sections
    }
}


extension SectionDao {
    fileprivate func createTable() -> Table {
        let table = Table("section")
        
        do {
            try! db.run(
                table.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Section.id,primaryKey: .autoincrement)
                    builder.column(Field_Section.title)
                    builder.column(Field_Section.sort)
                    builder.column(Field_Section.boardId)
                    builder.column(Field_Section.createdAt)
                })
            )
        }
        return table
    }
    
    
    
    
    fileprivate func generateSectionInsert(section: Section,conflict:OnConflict = OnConflict.fail) -> Insert {
        if section.id > 0 {
            return table.insert(or: conflict,
                                Field_Section.id <- section.id,
                                Field_Section.title <- section.title,
                                Field_Section.sort <- section.sort,
                                Field_Section.boardId <- section.boardId,
                                Field_Section.createdAt <- section.createdAt
            )
        }
        return table.insert(or: conflict,
                        Field_Section.title <- section.title,
                        Field_Section.sort <- section.sort,
                        Field_Section.boardId <- section.boardId,
                        Field_Section.createdAt <- section.createdAt
        )
    }
    
    fileprivate func generateSection(row: Row) -> Section {
        let board = Section(id: row[Field_Section.id], title: row[Field_Section.title], sort: row[Field_Section.sort], boardId: row[Field_Section.boardId], createdAt: row[Field_Section.createdAt])
        return board
    }
}
