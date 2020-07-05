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
    var sort:Double
    var categoryId:String // 分类id
    var type:Int // 1: user  2. 收集板
    var createdAt:Date
    
    init(id:String = UUID.init().uuidString,icon:String,title:String,sort:Double,categoryId:String="", type:Int = 1,createdAt:Date=Date()) {
        self.id = id
        self.icon = icon
        self.title = title
        self.sort = sort
        self.categoryId = categoryId
        self.type = type
        self.createdAt = createdAt
    }
    
    func getBoardIcon(fontSize:CGFloat) -> UIImage {
        if self.type  == BoardType.user.rawValue {
            return self.icon.emojiToImage(fontSize: fontSize)!
        }else {
            return UIImage(systemName: self.icon, pointSize: fontSize, weight: .light)!
        }
    }
    
    static func == (lhs: Board, rhs: Board) -> Bool {
        return lhs.id == rhs.id
    }
}


enum BoardType:Int {
    case user = 1
    case collect = 2
}


func getSystemBoard(type:BoardType) {
    
}
