//
//  NoteRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class NoteRepo:BaseRepo {
    static let shared = BlockRepo()
}

extension NoteRepo {
    func getNotes() -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [NoteInfo] in
                let notes   = try self.noteDao.query()
                var noteInfos:[NoteInfo] = []
                for note in notes {
                    noteInfos.append(NoteInfo(note: note, tags: []))
                }
                return noteInfos
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func createNote(_ note:Note) -> Observable<NoteInfo> {
        return Observable<NoteInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> NoteInfo in
                try self.noteDao.insert(note)
                return NoteInfo(note: note)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}

