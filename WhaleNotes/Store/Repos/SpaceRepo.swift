//
//  SpaceRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class SpaceRepo {
    static let shared = SpaceRepo()
    private init() {}
    
    private var db:SQLiteDatabase {
        return DBManager.shared.db
    }
    
    private var spaceDao:SpaceDao {
        return DBManager.shared.spaceDao
    }
    
    private var blockDao:BlockDao {
        return DBManager.shared.blockDao
    }
    
    func getSpace() -> Observable<Space> {
        return Observable<Space>.create {  observer -> Disposable in
            do {
                try self.db.transaction {
                    if let space = try self.spaceDao.query() {
                        observer.onNext(space)
                        return
                    }
                    var space = Space()
                    let collectBoard = Block.newBoardBlock(parent: space.id,parentTable: .space, properties: BlockBoardProperty(type:.collect))
                    try self.blockDao.insert(collectBoard)
                    
                    let toggle = Block.newToggleBlock(parent: space.id, parentTable: .space, properties: BlockToggleProperty())
                    try self.blockDao.insert(toggle)
                    
                    space.collectBoardId = collectBoard.id
                    space.boardGroupIds = [toggle.id]
                    try self.spaceDao.insert(space:space)
                    observer.onNext(space)
                }
            }catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func getSpaceAndBlocks() {

    }
}

