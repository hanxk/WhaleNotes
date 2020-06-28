//
//  Board.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import Foundation

// 记事板
struct Board: Hashable {
    var id:Int64 = 0
    var icon:String
    var title:String
    var sort:Double
    var categoryId:Int64 // 分类id
    var type:Int // 1: user  2. 收集板
    var createdAt:Date
    
    init(id:Int64=0,icon:String,title:String,sort:Double,categoryId:Int64=0, type:Int = 1,createdAt:Date=Date()) {
        self.id = id
        self.icon = icon
        self.title = title
        self.sort = sort
        self.categoryId = categoryId
        self.type = type
        self.createdAt = createdAt
    }
}


enum BoardType:Int {
    case user = 1
    case collect = 2
}


func getSystemBoard(type:BoardType) {
    
}
