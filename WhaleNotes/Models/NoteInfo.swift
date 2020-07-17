//
//  NoteInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/15.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

//一条笔记
struct NoteInfo {
    var noteBlock:BlockInfo!
    var textBlock:BlockInfo?
    var todoGroupBlock:BlockInfo?
    var attachmentGroupBlock:BlockInfo?
    
    init(noteBlock:BlockInfo) {
        self.noteBlock = noteBlock
        
        for blockInfo in noteBlock.contentBlocks {
            if blockInfo.blockTextProperties != nil {
                self.textBlock = blockInfo
                continue
            }
            guard let groupProperties = blockInfo.groupProperties else { continue }
            switch NoteInfoGroupTag.init(rawValue: groupProperties.tag)! {
            case .todo:
                self.todoGroupBlock = blockInfo
            case .attachment:
                self.attachmentGroupBlock = blockInfo
            }
        }
    }
    
    mutating func update(blockInfo:BlockInfo) {
        self.updatedAt = Date()
        switch blockInfo.type {
        case .note:
            self.noteBlock = blockInfo
        case .text:
            self.textBlock = blockInfo
        case .todo:
            if let index = self.todoGroupBlock?.contentBlocks.firstIndex(of: blockInfo) {
                self.todoGroupBlock?.contentBlocks[index] = blockInfo
                return
            }
            // 未找到，新增吧
            
        case .group:
            let tag = NoteInfoGroupTag.init(rawValue: blockInfo.groupProperties!.tag)!
            switch tag {
            case .todo:
                self.todoGroupBlock = blockInfo
                break
            case .attachment:
                self.attachmentGroupBlock = blockInfo
                break
            }
        default:
            break
        }
    }
    
    
    mutating func insert(blockInfo:BlockInfo,at i:Int) {
        self.updatedAt = Date()
        switch blockInfo.type {
        case .todo:
            self.todoGroupBlock?.contentBlocks.insert(blockInfo, at: i)
        default:
            break
        }

    }
    
    mutating func delete(blockInfo:BlockInfo) {
        self.updatedAt = Date()
        switch blockInfo.type {
        case .text:
            self.textBlock = nil
        case .todo:
            if let index = self.todoGroupBlock?.contentBlocks.firstIndex(of: blockInfo) {
                self.todoGroupBlock?.contentBlocks.remove(at: index)
            }
        case .group:
            let tag = NoteInfoGroupTag.init(rawValue: blockInfo.groupProperties!.tag)!
            switch tag {
            case .todo:
                self.todoGroupBlock = nil
                break
            case .attachment:
                self.attachmentGroupBlock = nil
                break
            }
        default:
            break
        }
    }
}

extension NoteInfo {
    mutating func deleteTodo(index:Int) {
        self.updatedAt = Date()
        self.todoGroupBlock?.contentBlocks.remove(at: index)
    }
    
    mutating func moveTodo(todoBlock:BlockInfo,from:Int,to:Int) {
        self.updatedAt = Date()
        self.todoGroupBlock?.contentBlocks.remove(at: from)
        self.todoGroupBlock?.contentBlocks.insert(todoBlock, at: to)
        
        self.todoGroupBlock!.contentBlocks.forEach {
            print("\($0.position) ---------- >      \($0.blockTodoProperties!.title)" )
        }
    }
}

extension NoteInfo {
    var id:String {
        return noteBlock.id
    }
    
    var updatedAt:Date {
        get { return noteBlock.updatedAt }
        set { noteBlock.updatedAt = newValue}
    }
    var status:NoteBlockStatus {
        get { return noteBlock.blockNoteProperties!.status }
        set { noteBlock.blockNoteProperties?.status = newValue}
    }
    
    var position:Double {
        return noteBlock.position
    }

    var properties:BlockNoteProperty {
        get { return noteBlock.blockNoteProperties!}
        set { noteBlock.blockNoteProperties = newValue}
    }
}

enum NoteInfoGroupTag:Int {
    case todo = 1
    case attachment = 2
}
