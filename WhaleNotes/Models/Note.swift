//
//  NoteInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct Note {
    
    var rootBlock:Block!
    var boards:[Board] = []
    
    var textBlock:Block?
    var id:Int64 {
        return rootBlock.id
    }
    
    var updatedAt:Date {
        get {
            return rootBlock.updatedAt
        }
        set {
            self.rootBlock.updatedAt = newValue
        }
    }
    
    init(rootBlock:Block,childBlocks:[Block]) {
        self.rootBlock = rootBlock
        self.textBlock = childBlocks.first { $0.type == BlockType.text.rawValue }
        self.imageBlocks = childBlocks.filter{$0.type == BlockType.image.rawValue }.sorted(by: {$0.createdAt > $1.createdAt})
        self.setupTodoBlocks(todoBlocks: childBlocks.filter{$0.type == BlockType.todo.rawValue}.sorted(by: {$0.sort < $1.sort}))
    }
    
    
    var rootTodoBlock:Block?
    var todoBlocks:[Block] = []
    
    var isContentEmpry:Bool {
        return rootBlock.text.isEmpty &&
            textBlock?.text.isEmpty ?? true &&
        imageBlocks.isEmpty &&
            rootTodoBlock == nil
    }
    
    private(set) var imageBlocks:[Block] = []
    
    var createdDateStr:String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return  dateFormatter.string(from: self.rootBlock.createdAt)
    }
    var updatedDateStr:String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return  dateFormatter.string(from: self.rootBlock.updatedAt)
    }
    
    var backgroundColor:String {
        get {
            return (rootBlock.properties["background_color"] as? String) ?? "#FFFFFF"
        }
        set {
            rootBlock.properties["background_color"] = newValue
        }
    }
}

extension Note {
    mutating func addImageBlocks(_ imageBlocks:[Block]) {
        self.rootBlock.updatedAt = Date()
        var sortedImageBlocks = imageBlocks
        sortedImageBlocks.sort(by: {$0.createdAt > $1.createdAt})
        self.imageBlocks.insert(contentsOf: sortedImageBlocks, at: 0)
    }
}

// todo handler
extension Note {
    mutating func setupTodoBlocks(todoBlocks:[Block]) {
        guard let rootTodoBlock = todoBlocks.first(where: {$0.parent == 0}) else { return }
        self.todoBlocks = todoBlocks.filter{$0.parent == rootTodoBlock.id}
        self.rootTodoBlock = rootTodoBlock
    }
}



extension Note {
    
    mutating func updateBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .note:
            self.rootBlock = block
        case .text:
            self.textBlock = block
        case .todo:
            self.updateTodoBlock(todoBlock: block)
        case .image:
            break
        case .none:
            break
        }
    }
    
    private mutating func updateTodoBlock(todoBlock:Block) {
        guard let index = self.todoBlocks.firstIndex(where: {$0.id == todoBlock.id}) else { return }
        self.rootBlock.updatedAt = Date()
        self.todoBlocks[index] = todoBlock
    }
    
    
    private mutating func removeTodoBlock(todoBlock:Block) {
        self.rootBlock.updatedAt = Date()
        
        if let rootTodoBlock = rootTodoBlock,todoBlock.id == rootTodoBlock.id {
            self.rootTodoBlock = nil
            self.todoBlocks.removeAll()
            return
        }
        
        guard let index = self.todoBlocks.firstIndex(where: {$0.id == todoBlock.id}) else { return }
        self.todoBlocks.remove(at: index)
    }
    
    mutating func addBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .text:
            self.textBlock = block
        case .todo:
            self.addTodoBlock(todoBlock: block)
        case .image:
            break
        case .none:
            break
        case .some(.note):
            break
        }
    }
    
    
    private mutating func addTodoBlock(todoBlock:Block) {
        self.rootBlock.updatedAt = Date()
        let newIndex = { () -> Int in
           if self.todoBlocks.isEmpty { return 0}
            let newIndex = self.todoBlocks.firstIndex(where: {$0.sort > todoBlock.sort}) ?? self.todoBlocks.count
           return newIndex
        }()
        self.todoBlocks.insert(todoBlock, at: newIndex)
    }
    
    
    func getTodoBlockIndex(todoBlock:Block) -> Int? {
        return self.todoBlocks.firstIndex(where: {$0.id == todoBlock.id})
    }
    
    mutating func removeBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .text:
            self.textBlock = nil
        case .todo:
            self.removeTodoBlock(todoBlock: block)
        case .image:
            break
        case .none:
            break
        case .some(.note):
            break
        }
    }
    
}
