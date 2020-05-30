//
//  Block2.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
struct Block2 {
    var id:Int64 = 0
    var type:String = ""
    
    var text:String = ""
    var isChecked:Bool = false
    var isExpand:Bool = true
    var source:String = ""
    var createdAt:Date = Date()
    var sort:Double = 0
    
    var noteId:Int64 = 0
    var blockId:Int64  = 0
    
    
    static func newTitleBlock() -> Block2 {
        var block = Block2()
        block.text = ""
        block.sort = 1
        block.type = BlockType.title.rawValue
        return block
    }
    
    static func newTextBlock(text: String = "",noteId:Int64=0) -> Block2 {
        var block = Block2()
        block.text = ""
        block.sort = 2
        block.noteId = noteId
        block.type = BlockType.text.rawValue
        return block
    }
    
    static func newTodoGroupBlock(text: String = "清单") -> Block2 {
        var block = Block2()
        block.type = BlockType.todo.rawValue
        block.text = text
        block.sort = 3
        return block
    }
    
    
    static func newTodoBlock(text: String = "",noteId:Int64 = 0,parent:Int64 = 0,sort:Double = 0) -> Block2 {
        var block = Block2()
        block.type = BlockType.todo.rawValue
        block.isChecked = false
        block.noteId = noteId
        block.blockId = parent
        block.sort = sort
        block.text = text
        return block
    }
    
    static func newImageBlock(imageUrl: String) -> Block2 {
        var block = Block2()
        block.type = BlockType.image.rawValue
        block.sort = 4
        block.source = imageUrl
        return block
    }
    
    
    
}


//@objc dynamic var id: String = UUID().uuidString
//@objc dynamic var type: String  = ""
//
//
//@objc dynamic var text: String = ""
//
//// todo
//@objc dynamic var isChecked: Bool = false
//// for todo group
//@objc dynamic var isExpand: Bool = true
//
//// image: url
//@objc dynamic var source: String = ""
//
//@objc dynamic var createAt: Date = Date()
