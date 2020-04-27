//
//  Block.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RealmSwift

class Block: Object{
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var type: String  = ""
    @objc dynamic var title: String = ""
    @objc dynamic var content: String = ""
    @objc dynamic var text: String = ""
    @objc dynamic var createAt: Date = Date()
    @objc dynamic var sort: Int = 0
    let images =  List<Image>()
    let todos =  List<Todo>()
    
    
    lazy var blockType:BlockType = BlockType(rawValue: type)!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["blockType"]
    }
    
    static func newTitleBlock() -> Block {
        let block = Block()
        block.type = BlockType.title.rawValue
        return block
    }
    
    static func newTextBlock() -> Block {
        let block = Block()
        block.type = BlockType.text.rawValue
        return block
    }
    
    static func newImageBlock() -> Block {
        let block = Block()
        block.type = BlockType.image.rawValue
        return block
    }
    
    static func newTodoBlock(note: Note) -> Block {
        let block = Block()
        block.type = BlockType.todo.rawValue
        block.todos.append(Todo(text: "",block: block))
        return block
    }
}


class Image: Object {
    
}

class Todo: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var isChecked: Bool = false
    @objc dynamic var text: String = ""
    @objc dynamic var sort: Int = 0
    @objc dynamic var createAt: Date = Date()
    @objc dynamic var block: Block?
    
    override static func primaryKey() -> String?{
        return "id"
    }
    
    convenience init(text: String,block: Block) {
        self.init()
        self.text = text
        self.block = block
    }
}

enum BlockType: String {
    case title = "title"
    case text = "text"
    case todo = "todo"
    case image = "image"
}
