//
//  Block2.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import Foundation
struct Block {
    var id:String = UUID.init().uuidString
    var type:String = ""
    var text:String = ""
    var isChecked:Bool = false
    var isExpand:Bool = true
    var source:String = ""
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    var sort:Double = 0
//    var noteId:String = ""
    var parentId:String = ""
    
    // note status:  -1: 删除  1: 正常  2: 归档
    var status:Int = 1
    
    var properties:[String:Any] = [:]
    
    static func newNoteBlock() -> Block {
        var block = Block()
        block.text = ""
        block.type = BlockType.note.rawValue
        return block
    }
    
    static func newTextBlock(text: String = "",parent:String="") -> Block {
        var block = Block()
        block.text = ""
        block.parentId = parent
        block.type = BlockType.text.rawValue
        return block
    }
    
    
    mutating func getProperty(key: String) -> Any? {
        return properties[key]
    }
    
    static func newTodoBlock(text: String = "",parent:String = "",sort:Double = 0) -> Block {
        var block = Block()
        block.type = BlockType.todo.rawValue
        block.isChecked = false
        block.parentId = parent
        block.sort = sort
        block.text = text
        return block
    }
    
    static func newImageBlock(imageUrl: String,parent:String="",properties:[String:Any] = [:]) -> Block {
        var block = Block()
        block.type = BlockType.image.rawValue
        block.sort = 4
        block.source = imageUrl
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    
    static func newBookmarkBlock(parent:String="",fetchInfo:ImageFetchInfo) -> Block {
        let properties:[String:Any] = [
            BlockBookmarkProperty.description.rawValue:fetchInfo.description,
            BlockBookmarkProperty.cover.rawValue:fetchInfo.cover,
            BlockBookmarkProperty.canonicalUrl.rawValue:fetchInfo.canonicalUrl,
        ]
        var block = Block()
        block.type = BlockType.bookmark.rawValue
        block.sort = 5
        block.text = fetchInfo.title
        block.parentId = parent
        block.source = fetchInfo.finalUrl
        block.properties = properties
        return block
    }
    
    
}

enum BlockType: String {
    case note = "note"
    case text = "text"
    case todo = "todo"
    case image = "image"
    case bookmark = "bookmark"
}


enum BlockBookmarkProperty: String {
    case description = "description"
    case cover = "cover"
    case canonicalUrl = "canonicalUrl"
}

enum NoteBlockStatus: Int {
    case trash = -1
    case normal = 1
    case archive = 2
}
