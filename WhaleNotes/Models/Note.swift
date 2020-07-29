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
    
    var rootTodoBlock:Block?
    var todoBlocks:[Block] = []
    
    // 图片，链接
    private(set) var attachmentBlocks:[Block] = []
    
//    var board:Board!
    
    init(rootBlock:Block,childBlocks:[Block]) {
        self.rootBlock = rootBlock
        
        for childBlock in childBlocks {
            if childBlock.type == BlockType.text {
                self.textBlock = childBlock
                continue
            }
            if childBlock.type == BlockType.todo {
                if childBlock.parentId == rootBlock.id {
                    self.rootTodoBlock = childBlock
                }else {
                    self.todoBlocks.append(childBlock)
                }
                continue
            }
            self.attachmentBlocks.append(childBlock)
        }
        
//        self.textBlock = childBlocks.first { $0.type == BlockType.text.rawValue }
//        self.attachmentBlocks = childBlocks.filter{$0.type ==  BlockType.image.rawValue && $0.type ==  BlockType.bookmark.rawValue }.sorted(by: {$0.createdAt > $1.createdAt})
        
//        self.todoBlocks = self.todoBlocks.sorted(by: {$0.sort < $1.sort})
//        self.board = board
    }
    
    
}

// help property
extension Note {
    
    var id:String {
        return rootBlock.id
    }
    var title:String {
        return rootBlock.blockNoteProperties?.title ?? ""
    }
    
    var text:String? {
        return textBlock?.blockTextProperties?.title
    }
    
    var updatedAt:Date {
        get {
            return rootBlock.updatedAt
        }
        set {
            self.rootBlock.updatedAt = newValue
        }
    }
    var status:NoteBlockStatus {
        get {
            return rootBlock.blockNoteProperties!.status
        }
    }
    
    var sort:Double {
        get {
//            return rootBlock.sort
            return 1
        }
        set {
//            self.rootBlock.sort = newValue
        }
    }
    
    var isContentEmpty:Bool {
        return rootBlock.blockNoteProperties?.title.isEmpty ?? true &&
               textBlock?.blockTextProperties?.title.isEmpty ?? true &&
                attachmentBlocks.isEmpty &&
                    rootTodoBlock == nil
    }
    
    
    var noteCardType:NoteCardType {
        
        return .normal
    }
    
    
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
            return rootBlock.blockNoteProperties!.backgroundColor
        }
        set {
            rootBlock.blockNoteProperties?.backgroundColor = newValue
        }
    }
}

extension Note {
    mutating func addImageBlocks(_ imageBlocks:[Block]) {
        self.rootBlock.updatedAt = Date()
        var sortedImageBlocks = imageBlocks
        sortedImageBlocks.sort(by: {$0.createdAt > $1.createdAt})
        self.attachmentBlocks.insert(contentsOf: sortedImageBlocks, at: 0)
    }
    
    mutating func replaceImageBlocks(_ imageBlocks: [Block]) {
        self.rootBlock.updatedAt = Date()
        self.attachmentBlocks = imageBlocks
    }
}

// todo handler
extension Note {
    mutating func setupTodoBlocks(todoBlocks:[Block]) {
        guard let rootTodoBlock = todoBlocks.first(where: {$0.parentId == self.id}) else { return }
        self.todoBlocks = todoBlocks.filter{$0.parentId == rootTodoBlock.id}
        self.rootTodoBlock = rootTodoBlock
    }
}



extension Note {
    
    mutating func updateBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        switch  block.type{
        case .note:
            self.rootBlock = block
        case .text:
            self.textBlock = block
        case .todo:
            self.updateTodoBlock(todoBlock: block)
        case .image:
            break
        default:
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
        switch  block.type{
        case .text:
            self.textBlock = block
        case .todo:
            self.addTodoBlock(todoBlock: block)
        case .image:
            break
        case .none:
            break
        default:
            break
        }
    }
    
    
    private mutating func addTodoBlock(todoBlock:Block) {
        self.rootBlock.updatedAt = Date()
//        let newIndex = { () -> Int in
//           if self.todoBlocks.isEmpty { return 0}
//            let newIndex = self.todoBlocks.firstIndex(where: {$0.sort > todoBlock.sort}) ?? self.todoBlocks.count
//           return newIndex
//        }()
//        self.todoBlocks.insert(todoBlock, at: newIndex)
    }
    
    
    func getTodoBlockIndex(todoBlock:Block) -> Int? {
        return self.todoBlocks.firstIndex(where: {$0.id == todoBlock.id})
    }
    
    mutating func removeBlock(block:Block) {
        self.rootBlock.updatedAt = Date()
        switch  block.type{
        case .text:
            self.textBlock = nil
        case .todo:
            self.removeTodoBlock(todoBlock: block)
        case .image:
            self.attachmentBlocks.removeAll(where: {$0.id == block.id})
            break
        case .none:
            break
        default:
            break
        }
    }
    
    mutating func removeAllImageBlocks() {
        self.rootBlock.updatedAt = Date()
        self.attachmentBlocks.removeAll()
    }
    
}

enum NoteCardType {
    case normal
    case image
    case bookmark
}
