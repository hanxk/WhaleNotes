//
//  Board.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import Foundation

// 记事板
struct Board {
    var id:Int64 = 0
    var icon:String
    var title:String
    var sort:Double
    var categoryId:Int64 // 分类id
    var createdAt:Date
    
    init(id:Int64=0,icon:String,title:String,sort:Double,categoryId:Int64=0,createdAt:Date=Date()) {
        self.id = id
        self.icon = icon
        self.title = title
        self.sort = sort
        self.categoryId = categoryId
        self.createdAt = createdAt
    }
}
