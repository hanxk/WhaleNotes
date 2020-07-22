//
//  BlockInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/13.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
struct BlockInfo:Equatable {
    static func == (lhs: BlockInfo, rhs: BlockInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    
    var id:String {
        return block.id
    }
    
    var ownerId:String {
        return blockPosition.ownerId
    }
    
    var parentId:String {
        return block.parentId
    }
    
    var block:Block
    var blockPosition:BlockPosition = BlockPosition()
    
    var contentBlocks:[BlockInfo] = []
    
    
    var position:Double {
        get { return blockPosition.position}
        set  { blockPosition.position = newValue}
    }
    
    var type:BlockType {
        return block.type
    }
    var updatedAt:Date {
        get { return self.block.updatedAt }
        set { self.block.updatedAt = newValue}
    }
}



extension BlockInfo {
    var blockNoteProperties:BlockNoteProperty? {
        get { self.block.properties as? BlockNoteProperty }
        set {  self.block.properties =  newValue }
    }
    var blockTextProperties:BlockTextProperty? {
        get { self.block.properties as? BlockTextProperty }
        set {  self.block.properties =  newValue }
    }
    var blockTodoProperties:BlockTodoProperty? {
        get { self.block.properties as? BlockTodoProperty }
        set {  self.block.properties =  newValue }
    }
    var blockImageProperties:BlockImageProperty? {
        get { self.block.properties as? BlockImageProperty }
        set {  self.block.properties =  newValue }
    }
    
    var blockBookmarkProperties:BlockBookmarkProperty? {
        get { self.block.properties as? BlockBookmarkProperty }
        set {  self.block.properties =  newValue }
    }
    
    var blockBoardProperties:BlockBoardProperty? {
        get { self.block.properties as? BlockBoardProperty }
        set {  self.block.properties =  newValue }
    }
    
    var blockToggleProperties:BlockToggleProperty? {
        get { self.block.properties as? BlockToggleProperty }
        set {  self.block.properties =  newValue }
    }
    
    var groupProperties:BlockGroupProperty? {
        get { self.block.blockGroupProperties }
        set {  self.block.blockGroupProperties =  newValue }
    }

}
