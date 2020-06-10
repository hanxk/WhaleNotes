//
//  BoardInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/6/5.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

struct BoardCategoryInfo {
    var category:BoardCategory!
    var boards:[Board]!
    
    var categoryId:Int64 {
        return category.id
    }
    
    mutating func insertBoard(_ board:Board) -> Int {
        let insertIndex = self.boards.firstIndex(where: {$0.sort > board.sort}) ?? 0
        self.boards.insert(board, at: insertIndex)
        return insertIndex
    }
}
