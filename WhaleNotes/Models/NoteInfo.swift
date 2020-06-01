//
//  NoteInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct NoteInfo {
    
    var note:Note
    var titleBlock:Block?
    var textBlock:Block?
    
    var id:Int64 {
        return note.id
    }
    
    init(note:Note,blocks:[Block]) {
        self.note = note
        self.titleBlock = blocks[0]
        self.textBlock = blocks.first { $0.type == BlockType.text.rawValue }
        self.todoBlockInfos = self.setupTodoBlocks(blocks: blocks)
        self.todoBlockInfos.forEach {
            mapTodoBlockInfos[$0.block.id] = $0
        }
        self.imageBlocks = blocks.filter{$0.type == BlockType.image.rawValue }.sorted(by: {$0.createdAt > $1.createdAt})
        
    }
    
    private(set) var todoBlockInfos:[BlockInfo] = [] {
        didSet {
            mapTodoBlockInfos.removeAll()
            todoBlockInfos.forEach {
                mapTodoBlockInfos[$0.block.id] = $0
            }
        }
    }
    private(set) var mapTodoBlockInfos:[Int64:BlockInfo] = [:]
    
    var isContentEmpry:Bool {
        return titleBlock?.text.isEmpty ?? true &&
            textBlock?.text.isEmpty ?? true &&
        imageBlocks.isEmpty &&
            todoBlockInfos.isEmpty
    }
    
    private(set) var imageBlocks:[Block] = []
}

extension NoteInfo {
    mutating func addImageBlocks(_ imageBlocks:[Block]) {
        self.note.updatedAt = Date()
        var sortedImageBlocks = imageBlocks
        sortedImageBlocks.sort(by: {$0.createdAt > $1.createdAt})
        self.imageBlocks.insert(contentsOf: sortedImageBlocks, at: 0)
    }
}

// todo handler
extension NoteInfo {
    
    private  func setupTodoBlocks(blocks:[Block]) -> [BlockInfo] {
        if blocks.isEmpty {
            return []
        }
        let todoGroups:[Block] = blocks.filter { $0.type == BlockType.todo.rawValue && $0.parentBlockId == 0 }.sorted(by: {$0.sort > $1.sort})
        if todoGroups.isEmpty {
            return []
        }
        var todoBlockInfos:[BlockInfo] = []
        for groupBlock in todoGroups {
            let childBlocks = blocks.filter { $0.type == BlockType.todo.rawValue && $0.parentBlockId == groupBlock.id }
                .sorted { $0.sort < $1.sort  }
            let blockInfo = BlockInfo(block: groupBlock,childBlocks: childBlocks)
            todoBlockInfos.append(blockInfo)
        }
        return todoBlockInfos
    }
    
    
    mutating func updateTodosSort(blockIdAndSorts:[Int64:Double]) {
        //        blocks.filter { $0.type == BlockType.todo.rawValue}.forEach {
        //            $0.sort
        //
        //        }
    }
    
    func getChildTodoBlocks(groupId: Int64) -> BlockInfo? {
        guard let index = todoBlockInfos.firstIndex(where: {$0.id == groupId}) else { return nil }
        return todoBlockInfos[index]
    }
}



extension NoteInfo {
    
    mutating func updateBlock(block:Block) {
        self.note.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .title:
            self.titleBlock = block
        case .text:
            self.textBlock = block
        case .todo:
            self.updateTodoBlock(todoBlock: block)
        case .todo_group:
            break
        case .image:
            break
        case .none:
            break
        }
    }
    
    private mutating func updateTodoBlock(todoBlock:Block) {
        
        self.note.updatedAt = Date()
        if todoBlock.parentBlockId == 0 { // 更新 group
            guard let index = todoBlockInfos.firstIndex(where: {$0.id == todoBlock.id}) else { return }
            self.todoBlockInfos[index].block = todoBlock
            return
        }
        
        guard let index = todoBlockInfos.firstIndex(where: {$0.id == todoBlock.parentBlockId}),
            let todoIndex = self.todoBlockInfos[index].childBlocks.firstIndex(where: {$0.id == todoBlock.id})
            else { return }
        
        if self.todoBlockInfos[index].childBlocks[todoIndex].sort == todoBlock.sort {
            self.todoBlockInfos[index].childBlocks[todoIndex] = todoBlock
        }else {
            //sort 变了
            self.todoBlockInfos[index].childBlocks.remove(at: todoIndex)
            addTodoBlock(todoBlock: todoBlock)
        }
        
    }
    
    private mutating func removeTodoBlock(todoBlock:Block) {
        self.note.updatedAt = Date()
        if todoBlock.parentBlockId == 0 {
            self.todoBlockInfos = self.todoBlockInfos.filter({
                $0.id != todoBlock.id
            })
            return
        }
        guard let index = todoBlockInfos.firstIndex(where: {$0.id == todoBlock.parentBlockId}),
            let todoIndex = self.todoBlockInfos[index].childBlocks.firstIndex(where: {$0.id == todoBlock.id})
            else { return }
        
        self.todoBlockInfos[index].childBlocks.remove(at: todoIndex)
    }
    
    
    mutating func addBlockInfo(blocksInfo:BlockInfo) {
        self.note.updatedAt = Date()
        self.todoBlockInfos.append(blocksInfo)
    }
    
    mutating func addBlock(block:Block) {
        self.note.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .title:
            self.titleBlock = block
        case .text:
            self.textBlock = block
        case .todo:
            self.addTodoBlock(todoBlock: block)
        case .todo_group:
            break
        case .image:
            break
        case .none:
            break
        }
    }
    
    
    private mutating func addTodoBlock(todoBlock:Block) {
        guard let index = todoBlockInfos.firstIndex(where: {$0.id == todoBlock.parentBlockId})
            else { return }
        self.note.updatedAt = Date()
        var insertIndex = self.todoBlockInfos[index].childBlocks.firstIndex(where: {$0.sort > todoBlock.sort}) ?? -1
        insertIndex = insertIndex == -1 ? self.todoBlockInfos[index].childBlocks.count : insertIndex
        self.todoBlockInfos[index].childBlocks.insert(todoBlock, at: insertIndex)
    }
    
    
    mutating func removeBlock(block:Block) {
        self.note.updatedAt = Date()
        let blockType = BlockType.init(rawValue: block.type)
        switch  blockType{
        case .title:
            self.titleBlock = nil
        case .text:
            self.textBlock = nil
        case .todo:
            self.removeTodoBlock(todoBlock: block)
        case .todo_group:
            break
        case .image:
            break
        case .none:
            break
        }
    }
    
}
