//
//  BaseRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class BlockRepo {
    static let shared = BlockRepo()
    private init() {}
    private var db:SQLiteDatabase {
        return DBManager.shared.db
    }
    private var blockDao:BlockDao {
        return DBManager.shared.blockDao
    }
    
    private var spaceDao:SpaceDao {
        return DBManager.shared.spaceDao
    }
}

//MARK: 通用方法
extension BlockRepo {
    func getBlocks(parentId:String) -> Observable<[Block]> {
        return Observable<[Block]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [Block] in
                let blocks = try self.blockDao.query(parentId: parentId)
                return blocks
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
                if block.parentId != parent.id || !parent.boardGroupIds.contains(block.id) {
                    throw DBError(message: "parent error")
                }
                try self.blockDao.insert(block)
                try self.spaceDao.update(boardGroupIds: parent.boardGroupIds)
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
    
}


extension BlockRepo {
    
    func deleteBlock(id:String,childNewParent:Block,newSpace:Space) -> Observable<Bool> {
        return Observable<Bool>.create {  observer -> Disposable in
            
            self.transactionTask(observable: observer) { () -> Bool in
               
                // 删除本身
                try self.blockDao.delete(id: id, includeChild: false)
                // child 移动
                try self.blockDao.updateBlockParentId(oldParentId: id, newParentId: childNewParent.id)
                // new parent 更新
                try self.blockDao.updateContent(id: childNewParent.id, content: childNewParent.content)
                
                try self.spaceDao.update(boardGroupIds: newSpace.boardGroupIds)
                
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}



//MARK: 工具方法
extension BlockRepo {
    
    private func executeTask<T>(observable:AnyObserver<T>,closure:()throws -> T) -> Disposable {
        do {
            let result:T = try closure()
            observable.onNext(result)
        }catch {
            observable.onError(error)
        }
        observable.onCompleted()
        return Disposables.create()
    }
    
    
    private func transactionTask<T>(observable:AnyObserver<T>,closure:()throws -> T) -> Disposable {
        do {
            var result:T!
            try self.db.transaction {
                result = try closure()
            }
            observable.onNext(result)
        }catch {
            observable.onError(error)
        }
        observable.onCompleted()
        return Disposables.create()
    }
    
}
