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
    var title:String = ""
    var remark:String = ""
    var type:BlockType!
    var status:BlockStatus = .normal
    var properties:Any!
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    
    static func note(title:String,parentId:String,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .note
        block.properties = BlockNoteProperty()
        
        let position = BlockPosition(blockId: block.id, ownerId:parentId, position: position)
        return BlockInfo(block: block, blockPosition: position)
    }
    
    
    
    static func bookmark(parentId:String,properties:BlockBookmarkProperty,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .bookmark
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: parentId, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    static func todoList(parentId:String,properties:BlockTodoListProperty = BlockTodoListProperty(),position:Double) -> BlockInfo {
        var block = Block()
        block.type = .todo_list
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: parentId, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    static func todo(parentId:String,properties:BlockTodoProperty = BlockTodoProperty(),position:Double) -> BlockInfo {
        var block = Block()
        block.type = .todo
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: parentId, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    static func image(parent:String,properties:BlockImageProperty,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .image
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: parent, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
    static func board(parent:String = "",title:String,properties:BlockBoardProperty,position:Double) -> BlockInfo {
        var block = Block()
        block.type = .board
        block.title = title
        block.properties = properties
        
        let blockPosition = BlockPosition(blockId: block.id, ownerId: parent, position: position)
        return BlockInfo(block: block, blockPosition: blockPosition)
    }
    
}

extension Block {
    var blockNoteProperties:BlockNoteProperty? {
        get { self.properties as? BlockNoteProperty }
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
    
    static func convert2LocalSystemBoard(board:Block) -> Block {
        guard let blockBoardProperty = board.blockBoardProperties else { return board }
        if blockBoardProperty.type == .collect {
            var newBoard = board
            var newProperty = blockBoardProperty
            newProperty.icon = "tray.full"
//            newProperty.title = "收集板"
            newBoard.properties = newProperty
            return newBoard
        }
        return  board
    }
    
    var propertiesJSON:String {
        return json(from: self.properties as! Encodable)!
    }
}

enum BlockType: String {
    case note = "note"
    case todo = "todo"
    case todo_list = "todo_list"
    case image = "image"
    case bookmark = "bookmark"
    case board = "board"
}

enum TableType: String {
    case block = "block"
    case space = "space"
}


struct BlockNoteProperty: Codable {
    var text:String = ""
}

struct BlockTodoProperty: Codable {
    var isChecked:Bool = false
}

struct BlockTodoListProperty: Codable {
    
}


struct BlockImageProperty: Codable {
    var url:String
    var width:Float
    var height:Float
}

struct BlockBoardProperty: Codable {
    var icon:String = ""
    var type:BoardType = .user
    
    func getBoardIcon(fontSize:CGFloat) -> UIImage {
        if self.type  == .user {
            return self.icon.emojiToImage(fontSize: fontSize)!
        }else {
            return UIImage(systemName: self.icon, pointSize: fontSize, weight: .light)!
        }
    }
}

struct BlockBookmarkProperty: Codable {
    var title:String = ""
//    var cover:String = ""
    var coverProperty:BlockImageProperty? =  nil
    var link:String = ""
    var description:String = ""
    var canonicalUrl:String = ""
}


enum BoardType:String,Codable {
    case user = "user"
    case collect = "collect"
}

enum BlockStatus: Int,Codable {
    case trash = -1
    case normal = 1
    case archive = 2
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
                      "title" TEXT,
                      "remark" TEXT,
                      "type" TEXT NOT NULL,
                      "status" INTEGER NOT NULL,
                      "properties" JSON NOT NULL,
                      "created_at" DATE DEFAULT (datetime('now')),
                      "updated_at" DATE DEFAULT (datetime('now'))
                    );
        """
    }
}

struct BlockConstants {
    static let position:Double = 65536
}
