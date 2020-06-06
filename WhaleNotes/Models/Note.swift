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
        self.setupTodoBlocks(blocks: childBlocks)
    }
    
    var todoToggleBlocks:[Block] = []
    private(set) var mapTodoBlocks:[Int64:[Block]] = [:]
    
    var isContentEmpry:Bool {
        return rootBlock.text.isEmpty &&
            textBlock?.text.isEmpty ?? true &&
        imageBlocks.isEmpty &&
            todoToggleBlocks.isEmpty
    }
    
    private(set) var imageBlocks:[Block] = []
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
    
    private  mutating func setupTodoBlocks(blocks:[Block]){
        if blocks.isEmpty {
            return
        }
        let todoToggleBlocks:[Block] = blocks.filter { $0.type == BlockType.toggle.rawValue && $0.parent == 0 }.sorted(by: {$0.sort > $1.sort})
        if todoToggleBlocks.isEmpty {
            return
        }
        self.todoToggleBlocks = todoToggleBlocks
        for todoTogleBlock in todoToggleBlocks {
            let childBlocks = blocks.filter { $0.type == BlockType.todo.rawValue && $0.parent == todoTogleBlock.id }
                .sorted { $0.sort < $1.sort  }
            mapTodoBlocks[todoTogleBlock.id] =  childBlocks
        }
    }
    
    func getChildTodoBlocks(parent: Int64) -> [Block] {
        if let todoBlocks =  mapTodoBlocks[parent] {
            return todoBlocks
        }
        return []
    }
    
    func getToggleBlockById(id: Int64) -> Block{
        return todoToggleBlocks.first { $0.id == id }!
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
        case .toggle:
            self.updateTodoToggleBlock(todoToggleBlock: block)
        case .image:
            break
        case .none:
            break
        }
    }
    
    private mutating func updateTodoBlock(todoBlock:Block) {
        self.rootBlock.updatedAt = Date()
        if let todoBlocks =  mapTodoBlocks[todoBlock.parent] {
            mapTodoBlocks[todoBlock.parent] = todoBlocks.map{
                if  $0.id == todoBlock.id {
                    return todoBlock
                }
                return $0
            }.sorted(by: {$0.sort < $1.sort})
        }
    }
    
    
    private mutating func updateTodoToggleBlock(todoToggleBlock:Block) {
        self.rootBlock.updatedAt = Date()
        guard let index = self.todoToggleBlocks.firstIndex(where: {$0.id == todoToggleBlock.id}) else { return }
        self.todoToggleBlocks[index] = todoToggleBlock

    }
    
    
    private mutating func removeTodoBlock(todoBlock:Block) {
        self.rootBlock.updatedAt = Date()
        if let todoBlocks =  mapTodoBlocks[todoBlock.parent] {
            mapTodoBlocks[todoBlock.parent] = todoBlocks.filter{ $0.id != todoBlock.id }
        }
    }
    
    mutating func addTodoToggleBlock(blockInfo: (Block,[Block])) {
        self.rootBlock.updatedAt = Date()
        self.todoToggleBlocks.append(blockInfo.0)
        self.mapTodoBlocks[blockInfo.0.id] = blockInfo.1
    }
    
    
    mutating func addBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .text:
            self.textBlock = block
        case .todo:
            self.addTodoBlock(todoBlock: block)
        case .toggle:
            break
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
        if let todoBlocks =  mapTodoBlocks[todoBlock.parent] {
            var newTodoBlocks = todoBlocks
            newTodoBlocks.append(todoBlock)
            mapTodoBlocks[todoBlock.parent] = newTodoBlocks.sorted(by: {$0.sort < $1.sort})
        }
    }
    
    
    mutating func removeBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .text:
            self.textBlock = nil
        case .todo:
            self.removeTodoBlock(todoBlock: block)
        case .toggle:
            break
        case .image:
            break
        case .none:
            break
        case .some(.note):
            break
        }
    }
    
}
