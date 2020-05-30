//
//  NoteUseCase.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift


class EditorUseCase {
    
    var disposebag = DisposeBag()
    
    func deleteNote(noteId: Int64,callback:@escaping (Bool)->Void) {
        Observable<Int64>.just(noteId)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteId)  -> Bool in
                let result =  DBStore.shared.deleteNote(id: noteId)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                callback($0)
            }, onError: { err in
                Logger.error(err)
            }, onCompleted: {
                
            }, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    
    func updateBlock(block:Block2,callback:@escaping (Bool)->Void) {
        Observable<Bool>.create {  observer -> Disposable in
            let result = DBStore.shared.updateBlock(block:block)
            switch result {
            case .success(let isSuccess):
                observer.onNext(isSuccess)
                observer.onCompleted()
            case .failure(let err):
                observer.onError(err)
            }
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: {
            callback($0)
        }, onError: {
            Logger.error($0)
        }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    func deleteBlock(block:Block2,callback:@escaping (Bool)->Void) {
        Observable<Block2>.just(block)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(block)  -> Bool in
                let result =  DBStore.shared.deleteBlock(block: block)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    func createBlock(block:Block2,callback:@escaping (Block2)->Void) {
        Observable<Block2>.just(block)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(block)  -> Block2 in
                let result =  DBStore.shared.createBlock(block: block)
                switch result {
                case .success(let block):
                    return block
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    func createBlockInfo(blockInfo:BlockInfo,callback:@escaping (BlockInfo)->Void) {
        Observable<BlockInfo>.just(blockInfo)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(blockInfo)  -> BlockInfo in
                let result =  DBStore.shared.createBlockInfo(blockInfo: blockInfo)
                switch result {
                case .success(let newBlockInfo):
                    return newBlockInfo
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    func updateAndInsertBlock(updatedBlock:Block2,insertedblock:Block2,callback:@escaping (Block2)->Void) {
        Observable<Block2>.create {  observer -> Disposable in
                let result = DBStore.shared.updateAndInsertBlock(updatedBlock: updatedBlock, insertedBlock: insertedblock)
                switch result {
                case .success(let insertedBlock):
                    observer.onNext(insertedBlock)
                    observer.onCompleted()
                case .failure(let err):
                    observer.onError(err)
                }
                return Disposables.create()
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
}
