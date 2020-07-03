//
//  SectionAndNote.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
// 同一个 note 可以位于多个 section
struct SectionAndNote {
    let id:String
    let sectionId:String
    let noteId:String
    let sort:Double
    
    init(id:String = UUID.init().uuidString,sectionId:String,noteId:String,sort:Double) {
        self.id = id
        self.sectionId = sectionId
        self.noteId = noteId
        self.sort = sort
    }
}
