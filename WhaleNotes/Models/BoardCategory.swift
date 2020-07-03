//
//  BoardCategory.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/5.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct BoardCategory {
    var id:String = UUID.init().uuidString
    var title:String
    var sort:Double
    var isExpand:Bool
    let createdAt:Date
}
