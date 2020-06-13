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
    
}
