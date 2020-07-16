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
}

extension NoteInfo {
    var id:String {
        return noteBlock.id
    }
    
    var updatedAt:Date {
        get { return noteBlock.updatedAt }
        set { noteBlock.updatedAt = newValue}
    }
    
    var position:Double {
        return noteBlock.position
    }

    var properties:BlockNoteProperty {
        get { return noteBlock.blockNoteProperties!}
        set { noteBlock.blockNoteProperties = newValue}
    }
    var status:NoteBlockStatus {
        return properties.status
    }
}

enum NoteInfoGroupTag:Int {
    case todo = 1
    case attachment = 2
}
