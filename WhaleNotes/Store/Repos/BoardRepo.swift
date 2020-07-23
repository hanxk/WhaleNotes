//
//  BoardRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class BoardRepo:BaseRepo {
    static let shared = BoardRepo()
    private override init() { }
}

extension BoardRepo {
    
    func getNotesCount(boardId:String,noteBlockStatus:NoteBlockStatus) -> Observable<Int> {
        return Observable<Int>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> Int in
                return try self.blockDao.queryNotesCountByBoardId(boardId, noteBlockStatus: .archive)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func updateBoardProperties(boardId:String,blockBoardProperties:BlockBoardProperty) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> Void in
                try self.blockDao.updateProperties(id: boardId, propertiesJSON: blockBoardProperties.toJSON())
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func delete(boardId:String) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> Void in
                
                try self.blockPositionDao.delete(ownerId: boardId)
                try self.blockPositionDao.delete(blockId: boardId)
                
                try self.blockDao.delete(id: boardId, includeChild: true)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
//    static let shared = BoardRepo()
//    private init() {}
//    
//    func getBoardInfos() {
//        
//    }
//    
//    func createBoard(board: Board) ->  Observable<Board> {
//        return Observable<Board>.just(board)
//                 .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                 .map({(board)  -> Board in
//                     let result =  DBStore.shared.createBoard(board: board)
//                     switch result {
//                     case .success(let insertedBoard):
//                         return insertedBoard
//                     case .failure(let err):
//                         throw err
//                     }
//                 })
//                 .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func createBoardCategory(boardCategory: BoardCategory) ->  Observable<BoardCategory> {
//        return Observable<BoardCategory>.just(boardCategory)
//                 .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                 .map({(boardCategory)  -> BoardCategory in
//                     let result =  DBStore.shared.createBoardCategory(boardCategory: boardCategory)
//                     switch result {
//                     case .success(let insertedBoardCategory):
//                         return insertedBoardCategory
//                     case .failure(let err):
//                         throw err
//                     }
//                 })
//                 .observeOn(MainScheduler.instance)
//    }
//    
//    func deleteBoard(boardId: String) ->  Observable<Bool>  {
//       return Observable<String>.just(boardId)
//                  .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                  .map({(boardId)  -> Bool in
//                      let result =  DBStore.shared.deleteBoard(boardId: boardId)
//                      switch result {
//                      case .success(let isSuccess):
//                          return isSuccess
//                      case .failure(let err):
//                          throw err
//                      }
//                  })
//                  .observeOn(MainScheduler.instance)
//    }
//    
//    func deleteBoardCategory(boardCategoryInfo: BoardCategoryInfo) ->  Observable<Bool>  {
//           return Observable<BoardCategoryInfo>.just(boardCategoryInfo)
//                      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                      .map({(boardCategoryInfo)  -> Bool in
//                          let result =  DBStore.shared.deleteBoardCategory(boardCategoryInfo: boardCategoryInfo)
//                          switch result {
//                          case .success(let isSuccess):
//                              return isSuccess
//                          case .failure(let err):
//                              throw err
//                          }
//                      })
//                      .observeOn(MainScheduler.instance)
//    }
//    
//    func updateBoardCategory(boardCategory: BoardCategory) ->  Observable<Bool>  {
//           return Observable<BoardCategory>.just(boardCategory)
//                      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                      .map({(boardCategory)  -> Bool in
//                          let result =  DBStore.shared.updateBoardCategory(boardCategory: boardCategory)
//                          switch result {
//                          case .success(let isSuccess):
//                              return isSuccess
//                          case .failure(let err):
//                              throw err
//                          }
//                      })
//                      .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func updateBoard(board: Board) ->  Observable<Bool>  {
//           return Observable<Board>.just(board)
//                      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//                      .map({(board)  -> Bool in
//                          let result =  DBStore.shared.updateBoard(board)
//                          switch result {
//                          case .success(let isSuccess):
//                              return isSuccess
//                          case .failure(let err):
//                              throw err
//                          }
//                      })
//                      .observeOn(MainScheduler.instance)
//    }
//    
//    func getBoardNotes() {
//        
//    }
//    
//    func getBoardsExistsTrashNote() -> Observable<[(Board,[Note])]> {
//        return Observable<[(Board,[Note])]>.create {  observer -> Disposable in
//            let results = DBStore.shared.queryExistsTrashNoteBoards()
//            switch results {
//               case .success(let s):
//                    observer.onNext(s)
//               case .failure(let err):
//                   observer.onError(err)
//               }
//            observer.onCompleted()
//            
//            return Disposables.create()
//        }
//        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//        .observeOn(MainScheduler.instance)
//    }
//    
//    func getSectionNoteInfos(boardId:String,noteBlockStatus: NoteBlockStatus = NoteBlockStatus.normal) -> Observable<[SectionNoteInfo]>  {
//
//        return Observable<[SectionNoteInfo]>.create {  observer -> Disposable in
//            let sectionsResult = DBStore.shared.getSectionsByBoardId(boardId)
//            let sectionNotesResult = DBStore.shared.getSectionNotesByBoardId(boardId,noteBlockStatus:noteBlockStatus)
//            
//            var result:[SectionNoteInfo] = []
//            var sections:[Section] = []
//            var sectionNotes:[String:[Note]] = [:]
//            
//            switch sectionsResult {
//               case .success(let s):
//                   sections = s
//               case .failure(let err):
//                   observer.onError(err)
//               }
//            
//            switch sectionNotesResult {
//               case .success(let n):
//                   sectionNotes = n
//               case .failure(let err):
//                   observer.onError(err)
//               }
//            
//            
//            for section in sections {
//                let notes = sectionNotes[section.id]  ?? []
//                result.append(SectionNoteInfo(section: section, notes: notes))
//            }
//            
//            
//            observer.onNext(result)
//            observer.onCompleted()
//            
//            return Disposables.create()
//        }
//        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//        .observeOn(MainScheduler.instance)
//    }
//    
//    func getBoardCategoryInfos() -> Observable<BoardInfo> {
//        return Observable<BoardInfo>.create { observer -> Disposable in
//            let systemBoardsResult = DBStore.shared.getSystemBoards()
//            let boardsResult = DBStore.shared.getNoCategoryBoards()
//            let boardCategoryInfoResult = DBStore.shared.getBoardCategoryInfos()
//            
//            var systemBoards:[Board] = []
//            var boards:[Board] = []
//            var boardCategoryInfos:[BoardCategoryInfo] = []
//            
//            
//            switch systemBoardsResult {
//            case .success(let boards):
//                systemBoards = boards
//            case .failure(let err):
//                observer.onError(err)
//            }
//            
//            switch boardsResult {
//            case .success(let newBoards):
//                boards = newBoards
//            case .failure(let err):
//                observer.onError(err)
//            }
//            
//            switch boardCategoryInfoResult {
//            case .success(let result):
//                boardCategoryInfos = result
//            case .failure(let err):
//                observer.onError(err)
//            }
//            
//            let result = BoardInfo(systemBoards: systemBoards, boards: boards, boardCategoryInfos: boardCategoryInfos)
//
//            observer.onNext(result)
//            observer.onCompleted()
//            
//            return Disposables.create()
//        }
//        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//        .observeOn(MainScheduler.instance)
//    }
//    
//    func getBoardCategoryInfos(noteId:String) -> Observable<(Board?,BoardInfo)>{
//        return getBoardCategoryInfos()
//            .map { boardInfo -> (Board?,BoardInfo) in
//                let boardResult = DBStore.shared.getBoardsByNoteId(noteId: noteId)
//                var board:Board? = nil
//                switch boardResult {
//                case .success(let b):
//                    board = b
//                case .failure(let err):
//                    throw err
//                }
//                return (board,boardInfo)
//            }
//    }
//    
//    

    
    
    
    
}
