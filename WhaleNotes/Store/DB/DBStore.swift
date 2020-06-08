//
//  DBStore.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import SQLite
import SQLite3


class DBStore {
    
    static let shared = DBStore()
    
    fileprivate var db: Connection {
        return SQLiteManager.manager.getDB()
    }
    
    fileprivate var blockDao:BlockDao!
    
    fileprivate var boardDao:BoardDao!
    fileprivate var boardCategoryDao:BoardCategoryDao!
    
    func setup() {
        blockDao = BlockDao(dbCon: db)
        
        boardDao = BoardDao(dbCon: db)
        boardCategoryDao = BoardCategoryDao(dbCon: db)
    }
    
    
    func createNote(blockTypes:[BlockType]) -> DBResult<Note> {
        do {
            var newBlocks:[Block] = []
            var noteBlock = Block.newNoteBlock()
            try db.transaction {
                
                let noteId = try blockDao.insert(noteBlock)
                noteBlock.id = noteId
                
                for blockType in blockTypes {
                    var block:Block?
                    switch blockType {
                    case .text:
                        block = Block.newTextBlock(noteId: noteId)
                    case .toggle:
                        block = Block.newToggleBlock(noteId: noteId)
                    default:
                        break
                    }
                    if var block = block {
                        let blockId = try blockDao.insert(block)
                        block.id = blockId
                        
                        // todo 默认添加一个空 todo
                        if block.type == BlockType.toggle.rawValue {
                            var todoBlock = Block.newTodoBlock(noteId: noteId, parent: blockId, sort: 65536)
                            let blockId = try blockDao.insert(todoBlock)
                            todoBlock.id = blockId
                            newBlocks.append(todoBlock)
                        }
                            
                        newBlocks.append(block)
                    }
                }
            }
            return DBResult<Note>.success(Note(rootBlock: noteBlock, childBlocks:newBlocks))
        } catch let error  {
            return DBResult<Note>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func deleteNote(id:Int64) -> DBResult<Bool> {
        do {
            try db.transaction {
                let isSuccess =  try blockDao.delete(id: id)
                if isSuccess {
                    _ = try blockDao.deleteByNoteId(noteId: id)
                }
            }
            return DBResult<Bool>.success(true)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func getAllNotes() -> DBResult<[Note]>  {
        do {
            let noteBlocks = try blockDao.queryByType(type: BlockType.note.rawValue)
            let noteInfos:[Note] = try noteBlocks.map {
                let blocks = try blockDao.query(noteId: $0.id)
                return Note(rootBlock: $0, childBlocks: blocks)
            }
            return DBResult<[Note]>.success(noteInfos)
        } catch let err {
            print(err)
            return DBResult<[Note]>.failure(DBError(code: .None))
        }
    }
    
    func createBlock(block: Block) -> DBResult<Block> {
        do {
            var insertedBlock = block
            try db.transaction {
                
                _ = try tryUpdateBlockDate(block: block)
                
                let blockId = try blockDao.insert(block)
                insertedBlock.id = blockId
                
            }
            return DBResult<Block>.success(insertedBlock)
        } catch _ {
            return DBResult<Block>.failure(DBError(code: .None))
        }
    }
    
    func createBlocks(blocks: [Block]) -> DBResult<[Block]> {
        do {

            _ = try tryUpdateBlockDate(block: blocks[0])
            
            var newBlocks:[Block] = blocks
            for (index,_) in blocks.enumerated() {
                let blockId = try blockDao.insert(newBlocks[index])
                newBlocks[index].id = blockId
                newBlocks[index].sort = Double(65536*(index+1))
            }
            return DBResult<[Block]>.success(newBlocks)
        } catch _ {
            return DBResult<[Block]>.failure(DBError(code: .None))
        }
    }
    
    func createToggleBlock(toggleBlock: Block) -> DBResult<(Block,[Block])> {
        do {
            var block = toggleBlock
            var childBlocks:[Block] = []
            try db.transaction {
                if toggleBlock.noteId == 0 {
                    throw DBError(code: .None, message: "noteid is 0")
                }
                
                _ = try tryUpdateBlockDate(block: block)
                
                let blockId = try blockDao.insert(block)
                block.id = blockId
                
                // todo 默认添加一个空 todo
                var todoBlock = Block.newTodoBlock(noteId: toggleBlock.noteId, parent: blockId, sort: 65536)
                let todoBlockId = try blockDao.insert(todoBlock)
                todoBlock.id = todoBlockId
                childBlocks.append(todoBlock)

            }
            return DBResult<(Block,[Block])>.success((block,childBlocks))
        } catch _ {
            return DBResult<(Block,[Block])>.failure(DBError(code: .None))
        }
    }
    
    func updateBlock(block: Block) -> DBResult<Block> {
        do {
            var isSuccess = false
            var updatedBlock = block
            try db.transaction {
                isSuccess = try tryUpdateBlockDate(block: block)
                if isSuccess {
                    updatedBlock.updatedAt = Date()
                    isSuccess = try blockDao.updateBlock(block: updatedBlock)
                }
            }
            return DBResult<Block>.success(updatedBlock)
        } catch let error  {
            return DBResult<Block>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func deleteToggleBlock(toggleBlock: Block) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try tryUpdateBlockDate(block: toggleBlock)
                if isSuccess {
                    _ = try blockDao.deleteByParent(parent: toggleBlock.id)
                    _ =  try blockDao.delete(id: toggleBlock.id)
                }
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func deleteBlock(block: Block) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try tryUpdateBlockDate(block: block)
                if isSuccess {
                    isSuccess = try blockDao.deleteByNoteId(noteId: block.id)
                }
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    private func tryUpdateBlockDate(block:Block) throws -> Bool  {
        var isSuccess = true
        if block.parent > 0 {
            isSuccess = try blockDao.updateUpdatedAt(id: block.parent, updatedAt: Date())
        }
        if block.noteId > 0 {
            isSuccess = try blockDao.updateUpdatedAt(id: block.noteId, updatedAt: Date())
        }
        return isSuccess
    }
}


extension DBStore {
    func getBoardCategoryInfos() -> DBResult<[BoardCategoryInfo]>  {
        do {
            var boardCategoryInfos:[BoardCategoryInfo] = []
            try db.transaction {
                boardCategoryInfos = try boardCategoryDao.queryAll().map({
                    let boards = try boardDao.queryAll(categoryId: $0.id)
                    return BoardCategoryInfo(category: $0, boards: boards)
                })
            }
            return DBResult<[BoardCategoryInfo]>.success(boardCategoryInfos)
        } catch let err {
            print(err)
            return DBResult<[BoardCategoryInfo]>.failure(DBError(code: .None))
        }
    }
    
    func getNoCategoryBoards() -> DBResult<[Board]>  {
        do {
            let boards:[Board] = try boardDao.queryAll(categoryId: 0)
            return DBResult<[Board]>.success(boards)
        } catch let err {
            print(err)
            return DBResult<[Board]>.failure(DBError(code: .None))
        }
    }
    
}
