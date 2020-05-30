//
//  BlockInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/28.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
struct BlockInfo {
    var block:Block2
    var childBlocks:[Block2] = []
    
    var id:Int64 {
        return block.id
    }
    var noteId:Int64 {
        return block.noteId
    }
}
