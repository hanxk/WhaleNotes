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
}

extension BlockRepo {
    func getBlocks(parentId:String) -> Observable<[Block]> {
        return Observable<[Block]>.create {  observer -> Disposable in
            do {
                let blocks = try self.blockDao.query(parentId: parentId)
                observer.onNext(blocks)
            }catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}
