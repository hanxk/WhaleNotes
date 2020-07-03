//
//  Section.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct Section {
    var id:String = UUID.init().uuidString
    let title:String
    let sort:Double
    let boardId:String
    let createdAt:Date
}
