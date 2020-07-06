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
        #if DEBUG
        db.trace { print($0) }
        #endif
        
        blockDao = BlockDao(dbCon: db)
        
        boardDao = BoardDao(dbCon: db)
        sectionDao = SectionDao(dbCon: db)
        boardCategoryDao = BoardCategoryDao(dbCon: db)
        
        sectionNoteDao = SectionAndNoteDao(dbCon: db)
    }
    
    func createNote(sectionId:String,noteBlock:Block,childBlocks:[Block]) -> DBResult<Note> {
        do {
            var note = noteBlock
            try db.transaction {
                
                // 获取当前 section 的排序
                let sort = try sectionNoteDao.queryFirst(sectionId: sectionId)?.sort ?? 0
                note.sort = sort == 0 ? 65536 : sort / 2
                try blockDao.insert(note)

                // 添加关联表
                _  = try sectionNoteDao.insert(SectionAndNote(sectionId: sectionId, noteId: note.id, sort: note.sort))
                
                for block in childBlocks {
                    try blockDao.insert(block)
                }
            }
            return DBResult<Note>.success(Note(rootBlock: note,childBlocks:childBlocks))
        } catch let error  {
            return DBResult<Note>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func createRootTodoBlock(noteId:String) -> DBResult<[Block]> {
        do {
            var blocks:[Block] = []
            try db.transaction {
                let rootTodoBlock = Block.newTodoBlock(parent:noteId,sort: 0)
                try blockDao.insert(rootTodoBlock)
                let todoBlock = Block.newTodoBlock(parent: rootTodoBlock.id,sort: 65536)
                try blockDao.insert(todoBlock)
                
                blocks.append(rootTodoBlock)
                blocks.append(todoBlock)
                
            }
            return DBResult<[Block]>.success(blocks)
        } catch let error  {
            return DBResult<[Block]>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func deleteNote(id:String) -> DBResult<Bool> {
        do {
            _ =  try blockDao.delete(id: id)
            return DBResult<Bool>.success(true)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func createBlock(block: Block) -> DBResult<Block> {
        do {
            let insertedBlock = block
            try db.transaction {
                _ = try tryUpdateBlockDate(block: block)
                try blockDao.insert(block)
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
                try blockDao.insert(newBlocks[index])
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
    
    
    func deleteNoteBlock(noteBlockId: String) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                // 删除自身
                isSuccess = try blockDao.delete(id: noteBlockId)
                // 删除 section_note
                if isSuccess {
                    isSuccess = try sectionNoteDao.deleteByNoteId(noteBlockId)
                }
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    
    func deleteNoteBlocks(noteBlockIds: [String]) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                // 删除自身
                isSuccess = try blockDao.deleteMultiple(noteBlockIds:noteBlockIds)
                // 删除 section_note
                if isSuccess {
                    isSuccess = try sectionNoteDao.deleteByNoteIds(noteBlockIds)
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
                isSuccess = try blockDao.delete(id: block.id)
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    func deleteImageBlocks(noteId: String) -> DBResult<Bool> {
        do {
            var isSuccess = false
            try db.transaction {
                isSuccess = try blockDao.updateUpdatedAt(id:noteId, updatedAt: Date())
                if isSuccess {
                    isSuccess = try blockDao.delete(noteId: noteId, type: BlockType.image.rawValue)
                    let imageBlocks = try blockDao.query(parentId: noteId,type:BlockType.image.rawValue)
                    try imageBlocks.forEach {
                        let path =  ImageUtil.sharedInstance.filePath(imageName: $0.source)
                        try FileManager.default.removeItem(at:path)
                    }
                }
            }
            return DBResult<Bool>.success(isSuccess)
        } catch let error  {
            return DBResult<Bool>.failure(DBError(code: .None,message: error.localizedDescription))
        }
    }
    
    
    private func tryUpdateBlockDate(block:Block) throws -> Bool  {
        var isSuccess = true
        if block.parentId.isNotEmpty {
            isSuccess = try blockDao.updateUpdatedAt(id: block.parentId, updatedAt: Date())
        }
        return isSuccess
    }
}


extension DBStore {
    
    func createBoard(board: Board) -> DBResult<Board> {
        do {
            var insertedBoard = board
            try db.transaction {
                try boardDao.insert(insertedBoard)
                // 创建一个 默认 section
                let section = Section(title: "", sort: 65536, boardId: insertedBoard.id, createdAt: Date())
                _ = try sectionDao.insert(section)
                
            }
            return DBResult<Board>.success(insertedBoard)
        } catch _ {
            return DBResult<Board>.failure(DBError(code: .None))
        }
    }
    
    func createBoardCategory(boardCategory: BoardCategory) -> DBResult<BoardCategory> {
        do {
            try db.transaction {
                try boardCategoryDao.insert(boardCategory)
            }
            return DBResult<BoardCategory>.success(boardCategory)
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
    
//    func updateNoteBoards(note:Note,boards:[Board]) -> DBResult<Note> {
//        do {
//            var isSuccess = true
//            var newNote = note
//            try db.transaction {
//                
//                for board in boards {
//                    
//                    // 判断是否绑定过
//                    let isExists = try sectionNoteDao.isExists(noteId: note.id, boardId: board.id)
//                    if isExists {
//                        continue
//                    }
//                    
//                    
//                    let sections =  try sectionDao.query(boardId: board.id)
//                    // 默认添加到第一个 section
//                    let section = sections[0]
//                    
//                    var sort = try sectionNoteDao.queryFirst(sectionId: section.id)?.sort ?? 0
//                    sort = sort == 0 ? 65536 : sort/2
//                    
//                    let sectionNode = SectionAndNote(sectionId: section.id, noteId: note.id, sort: sort)
//                    let id = try sectionNoteDao.insert(sectionNode)
//                    isSuccess = id > 0
//                    if !isSuccess  { break }
//                }
//                
//                // 删除已取消的 tag
//                for oldBoard in note.boards {
//                    if boards.contains(where: {$0.id == oldBoard.id}) {
//                        continue
//                    }
//                    isSuccess = try sectionNoteDao.deleteByBoardId(oldBoard.id, noteId: note.id)
//                    if !isSuccess  { break }
//                }
//                
//                // 更新时间
//                newNote.updatedAt = Date()
//                _ = try blockDao.updateUpdatedAt(id: note.id, updatedAt: Date())
//                
//            }
//            if !isSuccess {
//                return DBResult<Note>.failure(DBError())
//            }
//            newNote.boards = boards
//            return DBResult<Note>.success(newNote)
//        } catch _ {
//            return DBResult<Note>.failure(DBError(code: .None))
//        }
//    }
    
    func moveNote2Board(note:Note,board:Board) -> DBResult<Note> {
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
                let section =  try sectionDao.query(boardId: board.id)[0]
                
                // 获取当前 section 下的 第一个 sort
                var sort = try sectionNoteDao.queryFirst(sectionId: section.id)?.sort ?? 0
                sort = sort == 0 ? 65536 : sort/2
                newNote.sort  = sort
                
                let sectionNode = SectionAndNote(sectionId: section.id, noteId: note.id, sort: sort)
                let id = try sectionNoteDao.insert(sectionNode)
                isSuccess = id > 0
                
                if isSuccess {
//                    newNote.board = board
                }
                
            }
            
            if !isSuccess {
                return DBResult<Note>.failure(DBError())
            }
            
            return DBResult<Note>.success(newNote)
        } catch _ {
            return DBResult<Note>.failure(DBError(code: .None))
        }
    }
    
    
    func updateSectionAndNot(noteId:String,sectionId:String,newSectionId:String) -> DBResult<Bool> {
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
                boards = try boardDao.queryAll(categoryId:"",type: BoardType.collect.rawValue).map {
                    return getLocalSystemBoardInfo(board: $0)
                }
                if boards.count == 0 {
                    let collectBoard = Board(icon: "", title: "收集板", sort: 1,type:BoardType.collect.rawValue)
                    try boardDao.insert(collectBoard)
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
            let boards:[Board] = try boardDao.queryAll(categoryId: "")
            return DBResult<[Board]>.success(boards)
        } catch let err {
            print(err)
            return DBResult<[Board]>.failure(DBError(code: .None))
        }
    }
    
    
    func getBoardsByNoteId(noteId:String) -> DBResult<Board?>  {
        do {
            let board = try boardDao.queryByNoteBlockId(noteId)!
            return DBResult<Board?>.success(board)
        } catch let err {
            print(err)
            return DBResult<Board?>.failure(DBError(code: .None))
        }
    }
    
    
    func getLocalSystemBoardInfo(board:Board) -> Board {
        switch board.type {
        case 2:
            var collectBoard = board
            collectBoard.icon = "tray.full"
            return collectBoard
        default:
            return board
        }
        
    }
    
    func queryExistsTrashNoteBoards() -> DBResult<[(Board,[Note])]> {
        do {
            var results:[(Board,[Note])] = []
            try db.transaction {
                let boards = try boardDao.queryExistsTrashNoteBoards()
                for board in boards {
                    let rootBlocks = try blockDao.queryNoteBlocksByBoardId(board.id,noteBlockStatus:NoteBlockStatus.trash).sorted(by: { $0.1.updatedAt > $1.1.updatedAt})
                    var notes:[Note] = []
                    for rootBlock in rootBlocks {
                        
                        let block = rootBlock.1
                        
                        let childBlocks = try blockDao.query(noteId: block.id)
                        
                        var board:Board = try boardDao.queryByNoteBlockId(block.id)!
                        board = getLocalSystemBoardInfo(board: board)
                        
                          
                        let note = Note(rootBlock: block, childBlocks: childBlocks)
                        notes.append(note)
                    }
                    results.append((board,notes))
                }
            }
            return DBResult<[(Board,[Note])]>.success(results)
        }catch let err {
            print(err)
            return DBResult<[(Board,[Note])]>.failure(DBError(code: .None,message: err.localizedDescription))
        }
    }
    
    func searchNotes(keyword: String) -> DBResult<[NoteAndBoard]> {
        do {
            let noteAndBoards = try blockDao.searchNoteBlocks(keyword: keyword)
            return DBResult<[NoteAndBoard]>.success(noteAndBoards)
        }catch let err {
            print(err)
            return DBResult<[NoteAndBoard]>.failure(DBError(code: .None,message: err.localizedDescription))
        }
    }
    
    func getNotesByBoardId2(_ boardId:String,noteBlockStatus: NoteBlockStatus) ->DBResult<[Note]> {
        do {
            var notes:[Note] = []
            try db.transaction {
                let rootBlocks = try blockDao.queryNoteBlocksByBoardId(boardId,noteBlockStatus:noteBlockStatus)
                for rootBlock in rootBlocks {
                    
                    let block = rootBlock.1
                    let childBlocks = try blockDao.query(noteId: block.id)
                    
                    var board:Board = try boardDao.queryByNoteBlockId(block.id)!
                    board = getLocalSystemBoardInfo(board: board)
                    let note = Note(rootBlock: block, childBlocks: childBlocks)
                    notes.append(note)
                }
                
            }
            return DBResult<[Note]>.success(notes)
        }catch let err {
            print(err)
            return DBResult<[Note]>.failure(DBError(code: .None,message: err.localizedDescription))
        }
    }
    
    
    func getSectionNotesByBoardId(_ boardId:String,noteBlockStatus: NoteBlockStatus) ->DBResult<[String:[Note]]> {
        do {
            let sectionNotes:[String:[Note]] = try blockDao.querySectionNotes(boardId: boardId)
            return DBResult<[String:[Note]]>.success(sectionNotes)
        }catch let err {
            print(err)
            return DBResult<[String:[Note]]>.failure(DBError(code: .None,message: err.localizedDescription))
        }
    }
    
    func queryNotesCountByBoardId(_ boardId:String,noteBlockStatus: NoteBlockStatus) ->DBResult<Int64>  {
        do {
            let count = try blockDao.queryNotesCountByBoardId(boardId,noteBlockStatus:noteBlockStatus)
            return DBResult<Int64>.success(count)
        }catch let err {
            print(err)
            return DBResult<Int64>.failure(DBError(code: .None,message: err.localizedDescription))
        }
    }
    
    
    func getSectionsByBoardId(_ boardId:String) -> DBResult<[Section]> {
        do {
            var sections:[Section] = []
            try db.transaction {
                sections = try sectionDao.query(boardId: boardId)
                if sections.isEmpty {
                    // 增加一个默认 section
                    let section = Section(title: "default", sort: 65536, boardId: boardId, createdAt: Date())
                    try sectionDao.insert(section)
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

//MARK: Board
extension DBStore {
    func deleteBoard(boardId:String) -> DBResult<Bool> {
        do {
            try db.transaction {
                // 获取 image block
                let imageBocks = try blockDao.query(boardId:boardId, type: BlockType.image.rawValue)
                
                // 删除 所有block
                _ = try blockDao.deleteByBoardId(boardId:boardId)
                
                // 删除 section note
                _  = try sectionNoteDao.deleteByBoardId(boardId)
                
                // 删除 section
                _ = try sectionDao.deleteByBoardId(boardId: boardId)
                
                // 删除 board
                _ = try boardDao.delete(boardId)
                
                // 删除文件资源
                try imageBocks.forEach {
                    let path =  ImageUtil.sharedInstance.filePath(imageName: $0.source)
                    try FileManager.default.removeItem(at:path)
                }
            }
            return DBResult<Bool>.success(true)
        } catch let err {
            print(err)
            return DBResult<Bool>.failure(DBError(code: .None))
        }
    }
    
    func queryBoardByNoteId(noteId:String)-> DBResult<Board?>  {
        do {
            let board:Board? = try boardDao.queryByNoteBlockId(noteId)
            return DBResult<Board?>.success(board)
        } catch let err {
            print(err)
            return DBResult<Board?>.failure(DBError(code: .None))
        }
    }
    
    
    
    func getBoardCategoryInfos(noteId: String) -> DBResult<(Board?,[BoardCategoryInfo])>  {
        do {
            var boardInfos:(Board?,[BoardCategoryInfo])? = nil
            try db.transaction {
                let boardCategoryInfos:[BoardCategoryInfo] = try boardCategoryDao.queryAll().map({
                    let boards = try boardDao.queryAll(categoryId: $0.id)
                    return BoardCategoryInfo(category: $0, boards: boards)
                })
                boardInfos?.0 = try boardDao.queryByNoteBlockId(noteId)
                boardInfos?.1 = boardCategoryInfos
            }
            return DBResult<(Board?,[BoardCategoryInfo])>.success(boardInfos!)
        } catch let err {
            print(err)
            return DBResult<(Board?,[BoardCategoryInfo])>.failure(DBError(code: .None))
        }
    }
}
