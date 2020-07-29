//
//  EditorViewModel.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class EditorViewModel {
    
    private let noteInfoViewModel:NoteEidtorMenuModel
    
//    var noteInfoPub: PublishSubject<NoteInfo> {
//        return noteInfoViewModel.noteInfoPub
//    }
//    
    init(noteInfo:NoteInfo) {
        self.noteInfoViewModel = NoteEidtorMenuModel(model: noteInfo)
    }
    
    
    func updateTitle(title:String) {
        
    }
}
