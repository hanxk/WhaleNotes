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
    let id:Int64
    let sectionId:Int64
    let noteId:Int64
    let sort:Double
}
