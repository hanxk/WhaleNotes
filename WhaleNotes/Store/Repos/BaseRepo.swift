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
    var noteDao:NoteDao {
        return DBManager.shared.noteDao
    }
    var tagDao:TagDao {
        return DBManager.shared.tagDao
    }
    
    var noteTagDao:NoteTagDao {
        return DBManager.shared.noteTagDao
    }
    
    var noteFileDao:NoteFileDao {
        return DBManager.shared.noteFileDao
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

