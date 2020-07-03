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
    var noteId:String = ""
    var parent:String = ""
    
    // note status:  -1: 删除  1: 正常  2: 归档
    var status:Int = 1
    
    var properties:[String:Any] = [:]
    
    static func newNoteBlock() -> Block {
        var block = Block()
        block.text = ""
        block.type = BlockType.note.rawValue
        return block
    }
    
    static func newTextBlock(text: String = "",noteId:String) -> Block {
        var block = Block()
        block.text = ""
        block.noteId = noteId
        block.type = BlockType.text.rawValue
        return block
    }
    
    
    mutating func getProperty(key: String) -> Any? {
        return properties[key]
    }
    
    static func newTodoBlock(noteId:String,sort:Double = 0,text: String = "",parent:String = "") -> Block {
        var block = Block()
        block.type = BlockType.todo.rawValue
        block.isChecked = false
        block.noteId = noteId
        block.parent = parent
        block.sort = sort
        block.text = text
        return block
    }
    
    static func newImageBlock(imageUrl: String,noteId:String,properties:[String:Any] = [:]) -> Block {
        var block = Block()
        block.type = BlockType.image.rawValue
        block.sort = 4
        block.noteId = noteId
        block.source = imageUrl
        block.properties = properties
        return block
    }
    
    
    static func newBookmarkBlock(noteId:String,url: String,canonicalUrl:String,title:String,description:String,cover:String) -> Block {
        let properties:[String:Any] = [
            BlockBookmarkProperty.description.rawValue:description,
            BlockBookmarkProperty.cover.rawValue:cover,
            BlockBookmarkProperty.canonicalUrl.rawValue:canonicalUrl,
        ]
        var block = Block()
        block.type = BlockType.bookmark.rawValue
        block.sort = 5
        block.text = title
        block.noteId = noteId
        block.source = url
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
