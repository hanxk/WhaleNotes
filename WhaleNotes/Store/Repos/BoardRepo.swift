//
//  BoardRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift


class BoardRepo {
    
    static let shared = BoardRepo()
    private init() {}
    
    func getBoardInfos() {
        
    }
    
    func createBoard(board: Board) ->  Observable<Board> {
        return Observable<Board>.just(board)
                 .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                 .map({(board)  -> Board in
                     let result =  DBStore.shared.createBoard(board: board)
                     switch result {
                     case .success(let insertedBoard):
                         return insertedBoard
                     case .failure(let err):
                         throw err
                     }
                 })
                 .observeOn(MainScheduler.instance)
    }
    
    
    func createBoardCategory(boardCategory: BoardCategory) ->  Observable<BoardCategory> {
        return Observable<BoardCategory>.just(boardCategory)
                 .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                 .map({(boardCategory)  -> BoardCategory in
                     let result =  DBStore.shared.createBoardCategory(boardCategory: boardCategory)
                     switch result {
                     case .success(let insertedBoardCategory):
                         return insertedBoardCategory
                     case .failure(let err):
                         throw err
                     }
                 })
                 .observeOn(MainScheduler.instance)
    }
    
    
    func deleteBoardCategory(boardCategoryInfo: BoardCategoryInfo) ->  Observable<Bool>  {
           return Observable<BoardCategoryInfo>.just(boardCategoryInfo)
                      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                      .map({(boardCategoryInfo)  -> Bool in
                          let result =  DBStore.shared.deleteBoardCategory(boardCategoryInfo: boardCategoryInfo)
                          switch result {
                          case .success(let isSuccess):
                              return isSuccess
                          case .failure(let err):
                              throw err
                          }
                      })
                      .observeOn(MainScheduler.instance)
    }
    
    func updateBoardCategory(boardCategory: BoardCategory) ->  Observable<Bool>  {
           return Observable<BoardCategory>.just(boardCategory)
                      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                      .map({(boardCategory)  -> Bool in
                          let result =  DBStore.shared.updateBoardCategory(boardCategory: boardCategory)
                          switch result {
                          case .success(let isSuccess):
                              return isSuccess
                          case .failure(let err):
                              throw err
                          }
                      })
                      .observeOn(MainScheduler.instance)
    }
    
    
    func updateBoard(board: Board) ->  Observable<Bool>  {
           return Observable<Board>.just(board)
                      .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
                      .map({(board)  -> Bool in
                          let result =  DBStore.shared.updateBoard(board)
                          switch result {
                          case .success(let isSuccess):
                              return isSuccess
                          case .failure(let err):
                              throw err
                          }
                      })
                      .observeOn(MainScheduler.instance)
    }
    
    func getBoardNotes() {
        
    }
    
    func getBoardCategoryInfos() -> Observable<([Board] ,[BoardCategoryInfo])> {
        return Observable<([Board] ,[BoardCategoryInfo])>.create {  observer -> Disposable in
            
            let boardsResult = DBStore.shared.getNoCategoryBoards()
            let boardCategoryInfoResult = DBStore.shared.getBoardCategoryInfos()
            
            var boards:[Board] = []
            var boardCategoryInfos:[BoardCategoryInfo] = []
            
            switch boardsResult {
            case .success(let newBoards):
                boards = newBoards
            case .failure(let err):
                observer.onError(err)
            }
            
            switch boardCategoryInfoResult {
            case .success(let result):
                boardCategoryInfos = result
            case .failure(let err):
                observer.onError(err)
            }

            observer.onNext((boards,boardCategoryInfos))
            observer.onCompleted()
            
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
    }
}
