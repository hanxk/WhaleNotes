//
//  NoteInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct NoteInfo {
    var note:Note
    var tags:[Tag] = []
}

extension NoteInfo {
    var id:String {
        return self.note.id
    }
    
    var isEmpty:Bool {
        return note.title.isEmpty && note.content.isEmpty
        && (tags.count <=  1)
    }
}
