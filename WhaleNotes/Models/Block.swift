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
    var type:BlockType!
    var properties:Any!
    var content:[String] = []
    var parentId:String = ""
    var parentTable:TableType = .block
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    
    
    static func newNoteBlock(properties:BlockNoteProperty=BlockNoteProperty()) -> Block {
        var block = Block()
        block.type = BlockType.note
        block.properties = properties
        return block
    }
    
    
    static func newTextBlock(parent:String,properties:BlockTextProperty=BlockTextProperty()) -> Block {
        var block = Block()
        block.parentId = parent
        block.type = BlockType.text
        block.properties = properties
        return block
    }
    
    static func newTodoBlock(parent:String,sort:Double = 0,properties:BlockTodoProperty=BlockTodoProperty()) -> Block {
        var block = Block()
        block.type = BlockType.todo
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    static func newImageBlock(parent:String,properties:BlockImageProperty) -> Block {
        var block = Block()
        block.type = BlockType.image
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    static func newBoardBlock(parentId:String,parentTable:TableType,properties:BlockBoardProperty) -> Block {
        var block = Block()
        block.type = BlockType.board
        block.parentId = parentId
        block.parentTable = parentTable
        block.properties = properties
        return block
    }
    
    static func newToggleBlock(parent:String,parentTable:TableType,properties:BlockToggleProperty) -> Block {
        var block = Block()
        block.type = BlockType.toggle
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    static func newBookmarkBlock(parent:String,properties:BlockBookmarkProperty) -> Block {
        var block = Block()
        block.type = BlockType.bookmark
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    
}

extension Block {
    var blockNoteProperties:BlockNoteProperty? {
        get { self.properties as? BlockNoteProperty }
        set {  self.properties =  newValue }
    }
    var blockTextProperties:BlockTextProperty? {
        get { self.properties as? BlockTextProperty }
        set {  self.properties =  newValue }
    }
    var blockTodoProperties:BlockTodoProperty? {
        get { self.properties as? BlockTodoProperty }
        set {  self.properties =  newValue }
    }
    var blockImageProperties:BlockImageProperty? {
        get { self.properties as? BlockImageProperty }
        set {  self.properties =  newValue }
    }
    
    var blockBookmarkProperties:BlockBookmarkProperty? {
        get { self.properties as? BlockBookmarkProperty }
        set {  self.properties =  newValue }
    }
    
    var blockBoardProperties:BlockBoardProperty? {
        get { self.properties as? BlockBoardProperty }
        set {  self.properties =  newValue }
    }
    
    var blockToggleProperties:BlockToggleProperty? {
        get { self.properties as? BlockToggleProperty }
        set {  self.properties =  newValue }
    }
    
    static func convert2LocalSystemBoard(board:Block) -> Block {
        guard let blockBoardProperty = board.blockBoardProperties else { return board }
        if blockBoardProperty.type == .collect {
            var newBoard = board
            var newProperty = blockBoardProperty
            newProperty.icon = "tray.full"
            newProperty.title = "收集板"
            newBoard.properties = newProperty
            return newBoard
        }
        return  board
    }
    
    var propertiesJSON:String {
        return json(from: self.properties as! Encodable)!
    }
    var contentJSON:String {
        return json(from: self.content)!
    }
}

enum BlockType: String {
    case note = "note"
    case text = "text"
    case todo = "todo"
    case image = "image"
    case bookmark = "bookmark"
    case board = "board"
    case toggle = "toggle"
}

enum TableType: String {
    case block = "block"
    case space = "space"
}

protocol DBJSONable: Codable {
//    func toJSON() -> String
//    static func toStruct(json:String) -> Any
}

extension DBJSONable {
//    func toJSON() -> String {
//        let jsonData = try! JSONEncoder().encode(self)
//        let jsonString = String(data: jsonData, encoding: .utf8)!
//        return jsonString
//    }
}




struct BlockNoteProperty: Codable {
    var title:String = ""
    // note status:  -1: 删除  1: 正常  2: 归档
    var status:Int = 1
    var backgroundColor:String = "#FFFFFF"
}



struct BlockTextProperty: DBJSONable {
    var title:String = ""
}


struct BlockTodoProperty: DBJSONable {
    var title:String = ""
    var isChecked:Bool = false
}

struct BlockImageProperty: DBJSONable {
    
    var url:String
    var width:Float
    var height:Float
    
}

struct BlockBoardProperty: DBJSONable {
    var icon:String = ""
    var title:String = ""
    var type:BoardType = .user
}

struct BlockToggleProperty: DBJSONable {
    var title:String = ""
    var isFolded:Bool = false
}

struct BlockBookmarkProperty: DBJSONable {
    var title:String = ""
    var cover:String = ""
    var link:String = ""
    var description:String = ""
    var canonicalUrl:String = ""
}

enum BoardType:String,Codable {
    case user = "user"
    case collect = "collect"
}

enum NoteBlockStatus: Int {
    case trash = -1
    case normal = 1
    case archive = 2
}

extension Block:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "block" (
                      "id" TEXT UNIQUE NOT NULL,
                      "type" TEXT NOT NULL,
                      "properties" JSON NOT NULL,
                      "content" JSON NOT NULL,
                      "parent_id" TEXT NOT NULL,
                      "parent_table" TEXT NOT NULL,
                      "created_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                      "updated_at" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
        """
    }
}

