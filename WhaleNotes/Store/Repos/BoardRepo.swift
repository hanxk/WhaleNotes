//
//  BoardRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift


class BoardeRepo {
    
    static let shared = BoardeRepo()
    private init() {}
    
    func getBoardInfos() {
        
    }
    
    func createBoard() {
        
    }
    
    func updateBoard() {
        
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
