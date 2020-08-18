//
//  Board.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit

// 记事板
struct Board: Equatable,Hashable {
    var id:String
    var icon:String
    var title:String
    var position:Double
    var parentId:String // 分类id
    var type:Int // 1: user  2. 收集板
    var createdAt:Date
    
    init(id:String = UUID.init().uuidString,icon:String,title:String,position:Double,parentId:String="", type:Int = 1,createdAt:Date=Date()) {
        self.id = id
        self.icon = icon
        self.title = title
        self.position = position
        self.parentId = parentId
        self.type = type
        self.createdAt = createdAt
    }
    

    
    static func == (lhs: Board, rhs: Board) -> Bool {
        return lhs.id == rhs.id
    }
}

