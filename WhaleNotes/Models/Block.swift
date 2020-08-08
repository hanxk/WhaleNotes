//
//  Block2.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//
import UIKit
struct Block {
    var id:String = UUID.init().uuidString
    var type:BlockType!
    var properties:Any!
    var content:[String] = []
    var parentId:String = ""
    var parentTable:TableType = .block
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    
    
    static func note(title:String,parentId:String,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .note
        block.parentId = parentId
        block.properties = BlockNoteProperty(title: title)
        
        let position = BlockPosition(blockId: block.id, ownerId: block.parentId, position: position)
        return BlockInfo(block: block, blockPosition: position)
    }
    
    
    static func newNoteBlock(properties:BlockNoteProperty=BlockNoteProperty()) -> Block {
        var block = Block()
        block.type = .note
        block.properties = properties
        return block
    }
    
    
    static func newTextBlock(parent:String,properties:BlockTextProperty=BlockTextProperty()) -> Block {
        var block = Block()
        block.parentId = parent
        block.type = .text
        block.properties = properties
        return block
    }
    
    static func text(parentId:String,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .text
        block.parentId = parentId
        block.properties =  BlockTextProperty(title: "")
        
        let position = BlockPosition(blockId: block.id, ownerId: block.parentId, position: position)
        return BlockInfo(block: block, blockPosition: position)
    }
    
    static func todo(parentId:String,properties:BlockTodoProperty = BlockTodoProperty(),position:Double) -> BlockInfo {
        var block = Block()
        block.type = .todo
        block.parentId = parentId
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: block.parentId, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    static func newTodoBlock(parent:String,sort:Double = 0,properties:BlockTodoProperty=BlockTodoProperty()) -> Block {
        var block = Block()
        block.type = .todo
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    static func newImageBlock(parent:String,properties:BlockImageProperty) -> Block {
        var block = Block()
        block.type = .image
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    static func image(parent:String,properties:BlockImageProperty,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .image
        block.parentId = parent
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: block.parentId, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    
    static func newBoardBlock(parentId:String,parentTable:TableType,properties:BlockBoardProperty) -> Block {
        var block = Block()
        block.type = .board
        block.parentId = parentId
        block.parentTable = parentTable
        block.properties = properties
        return block
    }
    
    
    static func newToggleBlock(parent:String,parentTable:TableType,properties:BlockToggleProperty) -> Block {
        var block = Block()
        block.type = .toggle
        block.parentId = parent
        block.parentTable = parentTable
        block.properties = properties
        return block
    }
    
    static func toggle(parent:String,parentTable:TableType,properties:BlockToggleProperty=BlockToggleProperty(),position:Double = 0) -> BlockInfo {
        var block = Block()
        block.type = .toggle
        block.parentId = parent
        block.parentTable = parentTable
        block.properties = properties
        
        let position = BlockPosition(blockId: block.id, ownerId: block.parentId, position: position)
        return BlockInfo(block: block, blockPosition: position)
    }
    
    static func newBookmarkBlock(parent:String,properties:BlockBookmarkProperty) -> Block {
        var block = Block()
        block.type = .bookmark
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    
    static func group(parent:String,parentTable:TableType = .block,properties:BlockGroupProperty = BlockGroupProperty(),position:Double = 0) -> BlockInfo {
        var block = Block()
        block.type = .group
        block.parentId = parent
        block.parentTable = parentTable
        block.properties = properties
        
        let position = BlockPosition(blockId: block.id, ownerId: block.parentId, position: position)
        return BlockInfo(block: block, blockPosition: position)
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
    
    var blockGroupProperties:BlockGroupProperty? {
        get { self.properties as? BlockGroupProperty }
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
    case group = "group"
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
    func toJSON() -> String {
        return json(from: self)!
    }
}




struct BlockNoteProperty: Codable {
    var title:String = ""
    // note status:  -1: 删除  1: 正常  2: 归档
    var status:NoteBlockStatus = .normal
    var backgroundColor:String = NoteBackground.gray
    
    var background:UIColor {
        return UIColor(hexString: self.backgroundColor)
    }
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
    
    func getBoardIcon(fontSize:CGFloat) -> UIImage {
        if self.type  == .user {
            return self.icon.emojiToImage(fontSize: fontSize)!
        }else {
            return UIImage(systemName: self.icon, pointSize: fontSize, weight: .light)!
        }
    }
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


struct BlockGroupProperty: DBJSONable {
    var tag:Int = 0
}

enum BoardType:String,Codable {
    case user = "user"
    case collect = "collect"
}

enum NoteBlockStatus: Int,Codable {
    case trash = -1
    case normal = 1
    case archive = 2
}


enum NoteBackground {
    
    static let gray = "#FFFFFF"
    static let red = "#FBCFCE"//#FBCFCE
//    static let orange = "#FFE9A5"//#FDDFCC
    static let yellow = "#FCE9AD"//#FCE9AD
    static let green = "#F0FDB7"//#F0FDB7
//    static let cyan = "#CAFCEE"
    static let blue = "#C5EBFD"//#C5EBFD
    static let purple = "#CADDFD"//#CADDFD
    static let pink = "#FFC9E7"//#FFC9E7
    
    
//    static let gray = "#EEEEEE"
//    static let red = "#FFC2BA"//#FBCFCE
//    static let yellow = "#FEF49C"//#FCE9AD
//    static let green = "#B3FFA1"//#F0FDB7
//    static let blue = "#ADF4FF"//#C5EBFD
//    static let purple = "#B6CAFF"//#CADDFD
//    static let pink = "#FFC7C7"//#FFC9E7
    
//    var uicolor:UIColor {
//        return UIColor(hexString: self.rawValue)
//    }
//    var defaultColor:NoteBackground {
//        return .gray
//    }
}

extension Block:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "block" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "type" TEXT NOT NULL,
                      "properties" JSON NOT NULL,
                      "content" JSON NOT NULL,
                      "parent_id" TEXT NOT NULL,
                      "parent_table" TEXT NOT NULL,
                      "created_at" DATE DEFAULT (datetime('now')),
                      "updated_at" DATE DEFAULT (datetime('now'))
                    );
                
        """
    }
}

struct BlockConstants {
    static let position:Double = 65536
}
