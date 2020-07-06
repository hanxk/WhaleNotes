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
    var properties:Any!
    var parentId:String = ""
    var sort:Double = 0
    var createdAt:Date = Date()
    var updatedAt:Date = Date()
    
    var propertyJSON:String {
        let type = BlockType.init(rawValue: self.type)!
        switch type {
        case .note:
            return self.blockNoteProperties?.toJSON() ?? BlockNoteProperty().toJSON()
        case .text:
            return self.blockTextProperties?.toJSON() ?? BlockTextProperty().toJSON()
        case .todo:
            return self.blockTodoProperties?.toJSON() ?? BlockTodoProperty().toJSON()
        case .image:
            return self.blockImageProperties?.toJSON() ?? BlockImageProperty(url: "", width: 0, height: 0).toJSON()
        case .bookmark:
            return self.blockBookmarkProperties?.toJSON() ?? BlockBookmarkProperty().toJSON()
        }
    }
    
    static func newNoteBlock(properties:BlockNoteProperty=BlockNoteProperty()) -> Block {
        var block = Block()
        block.type = BlockType.note.rawValue
        block.properties = properties
        return block
    }
    
    
    static func newTextBlock(parent:String,properties:BlockTextProperty=BlockTextProperty()) -> Block {
        var block = Block()
        block.parentId = parent
        block.type = BlockType.text.rawValue
        block.properties = properties
        return block
    }
    
    static func newTodoBlock(parent:String,sort:Double = 0,properties:BlockTodoProperty=BlockTodoProperty()) -> Block {
        var block = Block()
        block.type = BlockType.todo.rawValue
        block.parentId = parent
        block.properties = properties
        block.sort = sort
        return block
    }
    
    static func newImageBlock(parent:String,properties:BlockImageProperty) -> Block {
        var block = Block()
        block.type = BlockType.image.rawValue
        block.sort = 4
        block.parentId = parent
        block.properties = properties
        return block
    }
    
    
    static func newBookmarkBlock(parent:String,properties:BlockBookmarkProperty) -> Block {
        var block = Block()
        block.type = BlockType.bookmark.rawValue
        block.parentId = parent
        block.properties = properties
        block.sort = 5
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
    
}

enum BlockType: String {
    case note = "note"
    case text = "text"
    case todo = "todo"
    case image = "image"
    case bookmark = "bookmark"
}

protocol DBJSONable: Codable {
    func toJSON() -> String
    static func toStruct(json:String) -> Any
}

extension DBJSONable {
    func toJSON() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        return jsonString
    }
}



struct BlockNoteProperty: DBJSONable {
    var title:String = ""
    // note status:  -1: 删除  1: 正常  2: 归档
    var status:Int = 1
    var backgroundColor:String = "#FFFFFF"
    
    static func toStruct(json: String) -> Any {
        let jsonData = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(BlockNoteProperty.self, from: jsonData)
            return data
        } catch {
            return BlockNoteProperty()
        }
    }
}



struct BlockTextProperty: DBJSONable {
    var title:String = ""
    static func toStruct(json: String) -> Any {
        let jsonData = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(BlockTextProperty.self, from: jsonData)
            return data
        } catch {
            return BlockTextProperty()
        }
    }
}


struct BlockTodoProperty: DBJSONable {
    var title:String = ""
    var isChecked:Bool = false
    static func toStruct(json: String) -> Any {
        let jsonData = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(BlockTodoProperty.self, from: jsonData)
            return data
        } catch {
            return BlockTodoProperty()
        }
    }
}

struct BlockImageProperty: DBJSONable {
    
    var url:String
    var width:Float
    var height:Float
    
    static func toStruct(json: String) -> Any {
        let jsonData = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(BlockImageProperty.self, from: jsonData)
            return data
        } catch {
            return BlockImageProperty(url: "", width: 0, height: 0)
        }
    }
    
}


struct BlockBookmarkProperty: DBJSONable {
    var title:String = ""
    var cover:String = ""
    var link:String = ""
    var description:String = ""
    var canonicalUrl:String = ""
    
    static func toStruct(json: String) -> Any {
        let jsonData = Data(json.utf8)
        let decoder = JSONDecoder()
        do {
            let data = try decoder.decode(BlockBookmarkProperty.self, from: jsonData)
            return data
        } catch {
            return BlockBookmarkProperty()
        }
    }
}

enum NoteBlockStatus: Int {
    case trash = -1
    case normal = 1
    case archive = 2
}
