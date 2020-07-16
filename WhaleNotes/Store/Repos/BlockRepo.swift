//
//  BaseRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class BlockRepo:BaseRepo {
    static let shared = BlockRepo()
    private override init() { }
//    private init() {}
//    private var db:SQLiteDatabase {
//        return DBManager.shared.db
//    }
//    private var blockDao:BlockDao {
//        return DBManager.shared.blockDao
//    }
//
//    private var spaceDao:SpaceDao {
//        return DBManager.shared.spaceDao
//    }
//
//    private var blockPositionDao:BlockPositionDao {
//        return DBManager.shared.blockPositionDao
//    }
}

//MARK: BlockInfo
extension BlockRepo {
    
    func getBlockInfos(id:String) -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [BlockInfo] in
                let blocks:[BlockInfo] = try self.blockDao.queryChilds(id: id)
                return blocks
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createBlock(_ block:Block,blockPosition:BlockPosition? = nil) -> Observable<BlockInfo> {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockInfo in
                
                try self.blockDao.insert(block)
                guard let blockPosition = blockPosition else { return BlockInfo(block: block, blockPosition: BlockPosition())}
                
                if  block.id != blockPosition.ownerId {
                    throw DBError(message: "owner_id error")
                }
                try self.blockPositionDao.insert(blockPosition)
                
                return BlockInfo(block: block, blockPosition: blockPosition)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
}

//MARK: 通用方法
extension BlockRepo {
    func getBlocks(parentId:String) -> Observable<[Block]> {
        return Observable<[Block]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [Block] in
                let blocks:[Block] = try self.blockDao.query(parentId: parentId)
                return blocks
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createBlock(_ blockInfo:BlockInfo) -> Observable<Bool> {
        return Observable<Bool>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                try self.blockDao.insert(blockInfo.block)
                try self.blockPositionDao.insert(blockInfo.blockPosition)
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createBlock(_ block:Block,parent:Block) -> Observable<(Block,Block)> {
        return Observable<(Block,Block)>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> (Block,Block) in
                
                if block.parentId != parent.id || !parent.content.contains(block.id) {
                    throw DBError(message: "parent error")
                }
                try self.blockDao.insert(block)
                // 更新 parent content
                try self.blockDao.updateBlock(block: parent)
                return (block,parent)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createBlock(_ block:Block,parent:Space) -> Observable<(Block,Space)> {
        return Observable<(Block,Space)>.create {  observer -> Disposable in
            
            self.transactionTask(observable: observer) { () -> (Block,Space) in
//                if block.parentId != parent.id || !parent.boardGroupIds.contains(block.id) {
//                    throw DBError(message: "parent error")
//                }
                try self.blockDao.insert(block)
//                try self.spaceDao.update(boardGroupIds: parent.boardGroupIds)
                return (block,parent)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func updateBlock(_ block:Block) -> Observable<Block> {
        return Observable<Block>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> Block in
                try self.blockDao.updateBlock(block: block)
                return block
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updateProperties(id:String,propertiesJSON:String) -> Observable<String> {
        return Observable<String>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> String in
                try self.blockDao.updateProperties(id: id, propertiesJSON: propertiesJSON)
                return id
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updateContent(id:String,content:[String]) -> Observable<String> {
        return Observable<String>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> String in
                try self.blockDao.updateContent(id: id, content: content)
                return id
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func deleteBlockInfo(blockId:String,includeChild:Bool) -> Observable<Bool> {
        return Observable<Bool>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                // 删除 position
                try self.blockPositionDao.delete(blockId: blockId,includeChild: includeChild)
                // 删除
                try self.blockDao.delete(id: blockId, includeChild: includeChild)
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
}


extension BlockRepo {
    
    func deleteBlockInfo(blockInfo:BlockInfo,childNewParent:BlockInfo) -> Observable<BlockInfo>  {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            
            self.transactionTask(observable: observer) { () -> BlockInfo in
               
                // 删除本身
                try self.blockDao.delete(id: blockInfo.id, includeChild: false)
                
                // child 移动
                try self.blockDao.updateBlockParentId(oldParentId: blockInfo.id, newParentId: childNewParent.id)
                
                // 删除 position
                try self.blockPositionDao.deleteByParentId(blockInfo.id)
                
                // 更新 parent
                var newParent = childNewParent
                let position = childNewParent.contentBlocks.count == 0 ? 65536 : childNewParent.contentBlocks[0].blockPosition.position
                for blockInfo in blockInfo.contentBlocks.reversed() {
                    
                    var block = blockInfo.block
                    block.parentId = childNewParent.block.id
                    
                    let blockPosition = BlockPosition(blockId: block.id, ownerId: childNewParent.id, position: position/2)
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
    
    func deleteBlock(id:String,childNewParent:Block,newSpace:Space) -> Observable<Bool> {
        return Observable<Bool>.create {  observer -> Disposable in
            
            self.transactionTask(observable: observer) { () -> Bool in
               
                // 删除本身
                try self.blockDao.delete(id: id, includeChild: false)
                // child 移动
                try self.blockDao.updateBlockParentId(oldParentId: id, newParentId: childNewParent.id)
                // new parent 更新
                try self.blockDao.updateContent(id: childNewParent.id, content: childNewParent.content)
                
//                try self.spaceDao.update(boardGroupIds: newSpace.boardGroupIds)
                
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updatePosition(blockPosition:BlockPosition) -> Observable<Bool> {
        return Observable<Bool>.create { [self]  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                try blockPositionDao.update(blockPosition)
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
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
}
