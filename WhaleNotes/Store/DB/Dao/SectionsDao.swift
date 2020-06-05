//
//  BoardsDao.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite

fileprivate enum Field_Sections{
    static let id = Expression<Int64>("id")
    static let title = Expression<String>("title")
    static let sort = Expression<Double>("sort")
    static let boardId = Expression<Int64>("board_id")
    static let createdAt = Expression<Date>("created_at")
}

class SectionDao {
    
    private var table: Table!
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
        let sectionData = table.filter(Field_Sections.id == id)
        let rows = try db.run(sectionData.delete())
        return rows > 0
    }
}


extension SectionDao {
    fileprivate func createTable() -> Table {
        let table = Table("section")
        
        do {
            try! db.run(
                table.create(ifNotExists: true, block: { (builder) in
                    builder.column(Field_Sections.id,primaryKey: .autoincrement)
                    builder.column(Field_Sections.title)
                    builder.column(Field_Sections.sort)
                    builder.column(Field_Sections.boardId)
                    builder.column(Field_Sections.createdAt)
                })
            )
        }
        return table
    }
    
    
    
    
    fileprivate func generateSectionInsert(section: Section,conflict:OnConflict = OnConflict.fail) -> Insert {
        if section.id > 0 {
            return table.insert(or: conflict,
                                Field_Sections.id <- section.id,
                                Field_Sections.title <- section.title,
                                Field_Sections.sort <- section.sort,
                                Field_Sections.boardId <- section.boardId,
                                Field_Sections.createdAt <- section.createdAt
            )
        }
        return table.insert(or: conflict,
                        Field_Sections.title <- section.title,
                        Field_Sections.sort <- section.sort,
                        Field_Sections.boardId <- section.boardId,
                        Field_Sections.createdAt <- section.createdAt
        )
    }
    
    fileprivate func generateSection(row: Row) -> Section {
        let board = Section(id: row[Field_Sections.id], title: row[Field_Sections.title], sort: row[Field_Sections.sort], boardId: row[Field_Sections.boardId], createdAt: row[Field_Sections.createdAt])
        return board
    }
}
