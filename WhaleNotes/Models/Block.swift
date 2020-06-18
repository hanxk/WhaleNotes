//
//  Block2.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import Foundation
struct Block {
    var id:Int64 = 0
    var type:String = ""
    
    var text:String = ""
    var isChecked:Bool = false
    var isExpand:Bool = true
    var source:String = ""
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    var sort:Double = 0
    var noteId:Int64 = 0
    var parent:Int64  = 0
    
    
    // block 的附加属性
//    var properties:String = "{}"{
//        didSet {
//            propertiesDic = properties.convertToDictionary(text: self.properties)
//        }
//    }
    
    var properties:[String:Any] = [:]
    
    static func newNoteBlock() -> Block {
        var block = Block()
        block.text = ""
        block.type = BlockType.note.rawValue
        return block
    }
    
    static func newTextBlock(text: String = "",noteId:Int64) -> Block {
        var block = Block()
        block.text = ""
        block.noteId = noteId
        block.type = BlockType.text.rawValue
        return block
    }
    
    
    mutating func getProperty(key: String) -> Any? {
        return properties[key]
    }
    
    static func newTodoBlock(noteId:Int64,sort:Double,text: String = "",parent:Int64 = 0) -> Block {
        var block = Block()
        block.type = BlockType.todo.rawValue
        block.isChecked = false
        block.noteId = noteId
        block.parent = parent
        block.sort = sort
        block.text = text
        return block
    }
    
    static func newImageBlock(imageUrl: String,noteId:Int64,properties:[String:Any] = [:]) -> Block {
        var block = Block()
        block.type = BlockType.image.rawValue
        block.sort = 4
        block.noteId = noteId
        block.source = imageUrl
        block.properties = properties
        return block
    }
    
    
    
}

enum BlockType: String {
    case note = "note"
    case text = "text"
    case todo = "todo"
    case image = "image"
}
