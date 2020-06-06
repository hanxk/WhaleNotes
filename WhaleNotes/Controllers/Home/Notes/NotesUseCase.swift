//
//  NotesUseCase.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/27.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift


class NotesUseCase {
    
    var disposebag = DisposeBag()
    
    func getAllNotes(callback:@escaping ([Note])->Void) {
        Observable<[Note]>.create { observer -> Disposable in
            let result =  DBStore.shared.getAllNotes()
            switch result {
            case .success(let notes):
                observer.onNext(notes)
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
    
    func createNewNote(blockTypes: [BlockType],callback:@escaping (Note)->Void) {
        
        Observable<[BlockType]>.just(blockTypes)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteInfo)  -> Note in
            let reuslt =  DBStore.shared.createNote(blockTypes:blockTypes)
                switch reuslt {
                case .success(let noteInfo):
                    return noteInfo
                    
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { noteInfo in
                callback(noteInfo)
            }, onError: { err in
                Logger.error(err)
                }, onCompleted: {
                    
            }, onDisposed: nil)
            .disposed(by: disposebag)
    }
}
