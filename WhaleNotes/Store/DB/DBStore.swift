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
    fileprivate var sectionDao:SectionDao!
    fileprivate var sectionNoteDao:SectionAndNoteDao!
    
    fileprivate var boardDao:BoardDao!
    fileprivate var boardCategoryDao:BoardCategoryDao!
    
    func setup() {
        blockDao = BlockDao(dbCon: db)
        
        boardDao = BoardDao(dbCon: db)
        sectionDao = SectionDao(dbCon: db)
        boardCategoryDao = BoardCategoryDao(dbCon: db)
        
        sectionNoteDao = SectionAndNoteDao(dbCon: db)
    }
    
    
    func createNote(sectionId:Int64,blockTypes:[BlockType]) -> DBResult<Note> {
        do {
            var newBlocks:[Block] = []
            var noteBlock = Block.newNoteBlock()
            try db.transaction {
                
                // 获取当前 section 的排序
                let sort = try sectionNoteDao.queryFirst(sectionId: sectionId)?.sort ?? 0
                noteBlock.sort = sort == 0 ? 65536 : sort / 2
                
                let noteId = try blockDao.insert(noteBlock)
                noteBlock.id = noteId
                
                // 添加关联表
                _  = try sectionNoteDao.insert(SectionAndNote(id: 0, sectionId: sectionId, noteId: noteId, sort: noteBlock.sort))
                
                for blockType in blockTypes {
                    var block:Block?
                    switch blockType {
                    case .text:
                        block = Block.newTextBlock(noteId: noteId)
                    case .todo:
                        block = Block.newTodoBlock(noteId:noteId, sort: 0)
                    default:
                        break
                    }
                    if var block = block {
                        let blockId = try blockDao.insert(block)
                        block.id = blockId
                        
                        //                        // todo 默认添加一个空 todo
                        if block.type == BlockType.todo.rawValue {
                            var todoBlock = Block.newTodoBlock(noteId: noteId, sort: 65536, text: "", parent: blockId)
                            let blockId = try blockDao.insert(todoBlock)
                            todoBlock.id = blockId
                            newBlocks.append(todoBlock)
                        }
                        //
                        newBlocks.append(block)
                    }
                }
            }
            return DBResult<Note>.success(Note(rootBlock: noteBlock, childBlocks:newBlocks))
        } catch let error  {
            return DBResult<Note>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func createRootTodoBlock(noteId:Int64) -> DBResult<[Block]> {
        do {
            var blocks:[Block] = []
            try db.transaction {
                var rootTodoBlock = Block.newTodoBlock(noteId:noteId, sort: 0)
                let rootTodoId = try blockDao.insert(rootTodoBlock)
                rootTodoBlock.id = rootTodoId
                
                var todoBlock = Block.newTodoBlock(noteId: noteId, sort: 65536, text: "", parent: rootTodoId)
                let blockId = try blockDao.insert(todoBlock)
                todoBlock.id = blockId
                
                blocks.append(rootTodoBlock)
                blocks.append(todoBlock)
                
            }
            return DBResult<[Block]>.success(blocks)
        } catch let error  {
            return DBResult<[Block]>.failure(DBError(code: .None,message: error.localizedDescription))
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
    
    
    func deleteNoteBlock(block: Block) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try tryUpdateBlockDate(block: block)
                if isSuccess {
                    // 删除自身
                    isSuccess = try blockDao.delete(id: block.id)
                    // 删除 child blocks
                    isSuccess = try blockDao.deleteByNoteId(noteId: block.id)
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
                    isSuccess = try blockDao.delete(id: block.id)
                    // 删除子 block
                    _ = try blockDao.deleteByParent(parent: block.id)
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
    
    func createBoard(board: Board) -> DBResult<Board> {
        do {
            var insertedBoard = board
            try db.transaction {
                let boardId = try boardDao.insert(insertedBoard)
                insertedBoard.id = boardId
            }
            return DBResult<Board>.success(insertedBoard)
        } catch _ {
            return DBResult<Board>.failure(DBError(code: .None))
        }
    }
    
    func createBoardCategory(boardCategory: BoardCategory) -> DBResult<BoardCategory> {
        do {
            var insertedBoardCategory = boardCategory
            try db.transaction {
                let boardCategoryId = try boardCategoryDao.insert(insertedBoardCategory)
                insertedBoardCategory.id = boardCategoryId
            }
            return DBResult<BoardCategory>.success(insertedBoardCategory)
        } catch _ {
            return DBResult<BoardCategory>.failure(DBError(code: .None))
        }
    }
    
    
    func updateBoard( _ board: Board) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try boardDao.updateBoard(board)
            }
            return DBResult<Bool>.success(isSuccess)
        } catch _ {
            return DBResult<Bool>.failure(DBError(code: .None))
        }
    }
    
    func updateBoardCategory(boardCategory: BoardCategory) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try boardCategoryDao.update(boardCategory)
            }
            return DBResult<Bool>.success(isSuccess)
        } catch _ {
            return DBResult<Bool>.failure(DBError(code: .None))
        }
    }
    
    
    func moveNote2Board(note:Note,boardId:Int64) -> DBResult<Note> {
        do {
            var isSuccess = false
            var newNote = note
            try db.transaction {
                newNote.updatedAt = Date()
                _ = try blockDao.updateUpdatedAt(id: note.id, updatedAt: Date())
                
                //删除当前 note 绑定的 board
                isSuccess =  try sectionNoteDao.deleteByNoteId(note.id)
                if !isSuccess { return }
                
                // 重新绑定
                let section =  try sectionDao.query(boardId: boardId)[0]
                
                // 获取当前 section 下的 第一个 sort
                var sort = try sectionNoteDao.queryFirst(sectionId: section.id)?.sort ?? 0
                sort = sort == 0 ? 65536 : sort/2
                newNote.sort  = sort
                
                let sectionNode = SectionAndNote(id: 0, sectionId: section.id, noteId: note.id, sort: sort)
                let id = try sectionNoteDao.insert(sectionNode)
                isSuccess = id > 0
            }
            
            if !isSuccess {
                return DBResult<Note>.failure(DBError())
            }
            
            return DBResult<Note>.success(newNote)
        } catch _ {
            return DBResult<Note>.failure(DBError(code: .None))
        }
    }
    
    
    func updateSectionAndNot(noteId:Int64,sectionId:Int64,newSectionId:Int64) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                if let sectionAndNote = try sectionNoteDao.queryBy(noteId: noteId, sectionId: sectionId) {
                    isSuccess = try sectionNoteDao.update(sectionAndNote)
                }
            }
            return DBResult<Bool>.success(isSuccess)
        } catch _ {
            return DBResult<Bool>.failure(DBError(code: .None))
        }
    }
    
    func deleteBoardCategory(boardCategoryInfo: BoardCategoryInfo) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try boardCategoryDao.delete(id: boardCategoryInfo.category.id)
                //重置 category id
                for board in boardCategoryInfo.boards {
                    _ = try boardDao.updateBoard(board)
                }
            }
            return DBResult<Bool>.success(isSuccess)
        } catch _ {
            return DBResult<Bool>.failure(DBError(code: .None))
        }
    }
    
    
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
    
    func getSystemBoards() -> DBResult<[Board]> {
        do {
            var boards:[Board] = []
            try db.transaction {
                boards = try boardDao.queryAll(categoryId: 0,type: 2)
                if boards.count == 0 {
                    var collectBoard = Board(icon: "🗂️", title: "收集板", sort: 1,type:BoardType.collect.rawValue)
                    let boardId = try boardDao.insert(collectBoard)
                    collectBoard.id = boardId
                    boards.append(getLocalSystemBoardInfo(board: collectBoard))
                }
            }
            
            return DBResult<[Board]>.success(boards)
        } catch let err {
            print(err)
            return DBResult<[Board]>.failure(DBError(code: .None))
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
    
    
    func getBoardsByNoteId(noteId:Int64) -> DBResult<[Board]>  {
        do {
            let boards:[Board] = try boardDao.queryByNoteBlockId(noteId).map{
                if $0.type == 2 {
                    return getLocalSystemBoardInfo(board: $0)
                }
                return $0
            }
            return DBResult<[Board]>.success(boards)
        } catch let err {
            print(err)
            return DBResult<[Board]>.failure(DBError(code: .None))
        }
    }
    
    
    func getLocalSystemBoardInfo(board:Board) -> Board {
        switch board.type {
        case 2:
            var collectBoard = board
            collectBoard.icon = "🗂️"
            return collectBoard
        default:
            return board
        }
        
    }
    
    
    func getNotesByBoardId(_ boardId:Int64) ->DBResult<[(Int64,Note)]> {
        do {
            var notes:[(Int64,Note)] = []
            try db.transaction {
                let rootBlocks = try blockDao.queryByBoardId(boardId)
                for rootBlock in rootBlocks {
                    
                    let sectionId = rootBlock.0
                    let block = rootBlock.1
                    
                    let childBlocks = try blockDao.query(noteId: block.id)
                    let note = Note(rootBlock: block, childBlocks: childBlocks)
                    notes.append((sectionId,note))
                }
            }
            return DBResult<[(Int64,Note)]>.success(notes)
        }catch let err {
            print(err)
            return DBResult<[(Int64,Note)]>.failure(DBError(code: .None,message: err.localizedDescription))
        }
    }
    
    func getSectionsByBoardId(_ boardId:Int64) -> DBResult<[Section]> {
        do {
            var sections:[Section] = []
            try db.transaction {
                sections = try sectionDao.query(boardId: boardId)
                if sections.isEmpty {
                    // 增加一个默认 section
                    var section = Section(id: 0, title: "", sort: 65536, boardId: boardId, createdAt: Date())
                    let sectionId = try sectionDao.insert(section)
                    section.id = sectionId
                    sections = [section]
                }
            }
            return DBResult<[Section]>.success(sections)
        } catch let err {
            print(err)
            return DBResult<[Section]>.failure(DBError(code: .None))
        }
    }
}
