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
    
    private var blockPositionDao:BlockPositionDao {
        return DBManager.shared.blockPositionDao
    }
    
    func getSpace() -> Observable<SpaceInfo> {
        return Observable<SpaceInfo>.create {  observer -> Disposable in
            do {
                try self.db.transaction {
                    if let space = try self.spaceDao.query() {
                        // 获取 childinfo
                        let blockInfos = try self.blockDao.queryChilds2(id: space.id)
                        
                        let collectBoard =  blockInfos.first{ $0.id == space.collectBoardId}!
                        let boardGroupBlock =  blockInfos.first{ $0.id == space.boardGroupId}!
                        
                        let categoryGroupBlock = blockInfos.first{ $0.id == space.categoryGroupId}!
                        
                        let spaceInfo = SpaceInfo(space: space, collectBoard: collectBoard, boardGroupBlock: boardGroupBlock, categoryGroupBlock: categoryGroupBlock)
                        observer.onNext(spaceInfo)
                        return
                    }
                    var space = Space()
                    
                    // 收集板
                    let collectBoard = Block.newBoardBlock(parentId: space.id,parentTable: .space, properties: BlockBoardProperty(type:.collect))
                    try self.blockDao.insert(collectBoard)
                    
                    // 存放单独的 boards
                    let boardGroupBlock = Block.toggle(parent: space.id, parentTable: .space)
                    try self.blockDao.insert(boardGroupBlock.block)
                    
                    // 存放 board 分类
                    let categoryGroupBlock = Block.group(parent: space.id,parentTable: .space)
                    try self.blockDao.insert(categoryGroupBlock.block)
                    
                    space.collectBoardId = collectBoard.id
                    space.boardGroupId = boardGroupBlock.id
                    space.categoryGroupId = categoryGroupBlock.id
                    
                    try self.spaceDao.insert(space:space)
                    
                    let spaceInfo = SpaceInfo(space: space,
                                              collectBoard: BlockInfo(block: Block.convert2LocalSystemBoard(board: collectBoard)),
                                boardGroupBlock: boardGroupBlock,
                                categoryGroupBlock: categoryGroupBlock)
                    
                    observer.onNext(spaceInfo)
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

