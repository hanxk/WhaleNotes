//
//  BaseRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/15.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

open class BaseRepo {
    var db:SQLiteDatabase {
        return DBManager.shared.db
    }
    var blockDao:BlockDao {
        return DBManager.shared.blockDao
    }
    
    
    var blockPositionDao:BlockPositionDao {
        return DBManager.shared.blockPositionDao
    }
    internal init() {}
}

//MARK: 工具方法
extension BaseRepo {
    
    internal func executeTask<T>(observable:AnyObserver<T>,closure:()throws -> T) -> Disposable {
        do {
            let result:T = try closure()
            observable.onNext(result)
        }catch {
            observable.onError(error)
        }
        observable.onCompleted()
        return Disposables.create()
    }
    
    
    internal func transactionTask<T>(observable:AnyObserver<T>,closure:()throws -> T) -> Disposable {
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


extension BaseRepo {
    internal func insertBlockInfo(blockInfo:BlockInfo) throws {
        try blockDao.insert(blockInfo.block)
        try blockPositionDao.insert(blockInfo.blockPosition)
    }
}
