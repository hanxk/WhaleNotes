//
//  Block.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RealmSwift
import Kingfisher

class Block: Object{
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var type: String  = ""
    
    
    @objc dynamic var text: String = ""
    
    // image
    @objc dynamic var imageName: String = ""
    
    // todo
    @objc dynamic var isChecked: Bool = false
    
    
    // image: url
    @objc dynamic var source: String = ""
    
    
    @objc dynamic var createAt: Date = Date()
    
    lazy var blockType:BlockType = BlockType(rawValue: type)!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["blockType"]
    }
    
    static func newTitleBlock() -> Block {
        let block = Block()
        block.text = ""
        block.type = BlockType.title.rawValue
        return block
    }
    
    static func newTextBlock() -> Block {
        let block = Block()
        block.text = ""
        block.type = BlockType.text.rawValue
        return block
    }
    
    static func newImageBlock(imageUrl: String) -> Block {
        let block = Block()
        block.type = BlockType.image.rawValue
        block.source = imageUrl
        return block
    }
    
    static func newTodoBlock(text: String = "") -> Block {
        let block = Block()
        block.type = BlockType.todo.rawValue
        block.isChecked = false
        block.text = ""
        return block
    }
}


//class Image: Object {
//    @objc dynamic var extention: String = ""
//    @objc dynamic var block: Block?
//
//    lazy var  localPath: URL = {
//        return ImageUtil.sharedInstance.dirPath.appendingPathComponent(block!.id+"."+extention)
//    }()
//
//    lazy var localPathProvider: LocalFileImageDataProvider = {
//        let fileURL = URL(fileURLWithPath: localPath.absoluteString)
//        let provider = LocalFileImageDataProvider(fileURL: fileURL)
//        return provider
//    }()
//
//
//    override static func ignoredProperties() -> [String] {
//        return ["localPath","localPathProvider"]
//    }
//}
//
//class Todo: Object {
//    @objc dynamic var isChecked: Bool = false
//    @objc dynamic var text: String = ""
//    @objc dynamic var block: Block?
//
//    convenience init(text: String,block: Block) {
//        self.init()
//        self.text = text
//        self.block = block
//    }
//}

enum BlockType: String {
    case title = "title"
    case text = "text"
    case todo = "todo"
    case image = "image"
}
