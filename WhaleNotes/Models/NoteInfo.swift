//
//  NoteInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import DeepDiff

struct NoteInfo {
    var note:Note
    var tags:[Tag] = []
}


extension NoteInfo {
    var id:String {
        return self.note.id
    }
    var status:NoteStatus {
        get { return note.status }
        set { self.note.status = newValue }
    }
    
    var isEmpty:Bool {
        return note.title.isEmpty && note.content.isEmpty
        && (tags.count <=  1)
    }
}

extension NoteInfo:DiffAware {
    
    typealias DiffId = String
    var diffId: DiffId { return self.id }
    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        (a.id == b.id) && (a.note.updatedAt  ==  b.note.updatedAt) 
    }
}
