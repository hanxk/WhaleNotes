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
    
    fileprivate var noteDao:NoteDao!
    fileprivate var blockDao:BlockDao!
    
    fileprivate var boardDao:BoardDao!
    fileprivate var boardCategoryDao:BoardCategoryDao!
    
    func setup() {
        blockDao = BlockDao(dbCon: db)
        noteDao = NoteDao(dbCon: db)
        
        boardDao = BoardDao(dbCon: db)
        boardCategoryDao = BoardCategoryDao(dbCon: db)
    }
    
    
    func createNote(blocks:[Block]) -> DBResult<NoteInfo> {
        do {
            var newBlocks:[Block] = []
            var note = Note()
            try db.transaction {
                let noteId = try noteDao.insert(note)
                note.id = noteId
                
                for block in blocks {
                    var newBlock = block
                    newBlock.noteId = noteId

                    let blockId = try blockDao.insert(newBlock)
                    newBlock.id = blockId

                    newBlocks.append(newBlock)

                    // todo 默认添加一个空 todo
                    if newBlock.type == BlockType.todo.rawValue &&  newBlock.parentBlockId == 0{
                        var todoBlock = Block.newTodoBlock(text: "", noteId: noteId, parent: blockId, sort: 65536)
                        let blockId = try blockDao.insert(todoBlock)
                        todoBlock.id = blockId
                        newBlocks.append(todoBlock)
                    }
                }
            }
            
            return DBResult<NoteInfo>.success(NoteInfo(note: note, blocks:newBlocks))
        } catch let error  {
            return DBResult<NoteInfo>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func deleteNote(id:Int64) -> DBResult<Bool> {
        do {
            try db.transaction {
                let isSuccess =  try noteDao.delete(id: id)
                if isSuccess {
                    _ = try blockDao.deleteBlocksByNoteId(noteId: id)
                }
            }
            return DBResult<Bool>.success(true)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func getAllNotes() -> DBResult<[NoteInfo]>  {
        do {
            let notes = try noteDao.queryAll()
            let noteInfos:[NoteInfo] = try notes.map {
                let blocks = try blockDao.query(noteId: $0.id)
                return NoteInfo(note: $0, blocks: blocks)
            }
            return DBResult<[NoteInfo]>.success(noteInfos)
        } catch let err {
            print(err)
            return DBResult<[NoteInfo]>.failure(DBError(code: .None))
        }
    }
    
    func createBlock(block: Block) -> DBResult<Block> {
        do {
            var insertedBlock = block
            let blockId = try blockDao.insert(block)
            insertedBlock.id = blockId
            return DBResult<Block>.success(insertedBlock)
        } catch _ {
            return DBResult<Block>.failure(DBError(code: .None))
        }
    }
    
    func createBlocks(blocks: [Block]) -> DBResult<[Block]> {
        do {
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
    
    func createBlockInfo(blockInfo: BlockInfo) -> DBResult<BlockInfo> {
        do {
            var newBlockInfo:BlockInfo!
            try db.transaction {
                var block = blockInfo.block
                
                if block.noteId == 0 {
                    throw DBError(code: .None, message: "noteid is 0")
                }
                
                let blockId = try blockDao.insert(block)
                block.id = blockId
                
                
                var childBlocks:[Block] = blockInfo.childBlocks
                for (index,_) in childBlocks.enumerated() {
                    childBlocks[index].parentBlockId = blockId
                    childBlocks[index].noteId = block.noteId
                    childBlocks[index].sort = Double(65536*(index+1))
                    let childBlockId = try blockDao.insert( childBlocks[index])
                    childBlocks[index].id = childBlockId
                }
                
                newBlockInfo = BlockInfo(block: block, childBlocks: childBlocks)
            }
            return DBResult<BlockInfo>.success(newBlockInfo)
        } catch _ {
            return DBResult<BlockInfo>.failure(DBError(code: .None))
        }
    }
    
    
    
    func updateBlockText(id: Int64,noteId:Int64, text: String) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                _ = try noteDao.updateUpdatedAt(id: noteId)
                isSuccess = try blockDao.updateText(id: id, text: text)
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func updateBlock(block: Block) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                _ = try noteDao.updateUpdatedAt(id: block.noteId)
                isSuccess = try blockDao.updateBlock(block: block)
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func updateAndInsertBlock(updatedBlock: Block,insertedBlock: Block) -> DBResult<Block> {
        do {
            var isSuccess = false
            var newBlock = insertedBlock
            try db.transaction {
                _ = try noteDao.updateUpdatedAt(id: updatedBlock.noteId)
                isSuccess = try blockDao.updateBlock(block: updatedBlock)
                if isSuccess {
                    newBlock.id = try blockDao.insert(insertedBlock)
                }
            }
            if newBlock.id == 0 {
                throw DBError(code: .None,message: "新增失败")
            }
            return DBResult<Block>.success(newBlock)
        } catch let error  {
            return DBResult<Block>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    
    func deleteBlock(block: Block) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                _ = try noteDao.updateUpdatedAt(id: block.noteId)
                isSuccess = try blockDao.deleteBlock(blockId: block.id)
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
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
    
    
    
}
