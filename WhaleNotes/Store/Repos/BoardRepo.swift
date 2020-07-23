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
    
}

//MARK: 侧边栏
extension BoardRepo {
    
    func updatePositionAndParent(blockPosition:BlockPosition) -> Observable<Bool> {
        return Observable<Bool>.create { [self]  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                try blockPositionDao.update(blockPosition)
                try blockDao.updateBlockParentId(id: blockPosition.blockId, newParentId: blockPosition.ownerId)
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updatePosition(blockPosition:BlockPosition) -> Observable<Void> {
        return Observable<Void>.create { [self]  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try blockPositionDao.update(blockPosition)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    /// 返回新的 category
    func deleteBoardCategory(_ boardCategory:BlockInfo,childNewCategory:BlockInfo) -> Observable<BlockInfo>  {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            
            self.transactionTask(observable: observer) { () -> BlockInfo in
               
                // 删除本身
                try self.blockDao.delete(id: boardCategory.id, includeChild: false)
                
                // child 移动到新的 category
                try self.blockDao.updateBlockParentId(oldParentId: boardCategory.id, newParentId: childNewCategory.id)
                
                // 删除 position
                try self.blockPositionDao.delete(ownerId: boardCategory.id)
                
                // 更新 parent
                var newParent = childNewCategory
                let position = childNewCategory.contentBlocks.count == 0 ? 65536 : childNewCategory.contentBlocks[0].blockPosition.position
                for blockInfo in boardCategory.contentBlocks.reversed() {
                    
                    var block = blockInfo.block
                    block.parentId = childNewCategory.block.id
                    
                    let blockPosition = BlockPosition(blockId: block.id, ownerId: childNewCategory.id, position: position/2)
                    try self.blockPositionDao.insert(blockPosition)
                    
                    let newBlockInfo = BlockInfo(block: block, blockPosition: blockPosition)
                    newParent.contentBlocks.insert(newBlockInfo, at: 0)
                }
                return newParent
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}
