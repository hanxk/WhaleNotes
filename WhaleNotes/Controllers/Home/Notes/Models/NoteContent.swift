//
//  NoteContent.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/22.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RealmSwift

struct NoteContent {
    var title:String
    var text:String
    var todosRef:ThreadSafeReference<List<Block>>?
    var imagesRef:ThreadSafeReference<List<Block>>?
    
    init(note:Note) {
        self.title = note.titleBlock?.text ?? ""
        self.text = note.textBlock?.text ?? ""
        if !note.todoBlocks.isEmpty {
            self.todosRef = ThreadSafeReference(to: note.todoBlocks)
        }
        if !note.attachBlocks.isEmpty {
            self.imagesRef = ThreadSafeReference(to: note.attachBlocks)
        }
    }
}
