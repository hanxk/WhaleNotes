//
//  Note.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct Note {
    var id: Int64
    var blocks:[NoteBlock]
    var createAt: Date
    var updateAt: Date
    
    func clone(id:Int64? = nil,blocks: [NoteBlock]? = nil) -> Note {
        return  Note(id: id ?? self.id, blocks: blocks ?? self.blocks, createAt: createAt, updateAt: updateAt)
    }
}
