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
    
    var categoryId:String {
        return category.id
    }
    
    mutating func insertBoard(_ board:Board) -> Int {
        let insertIndex = self.boards.firstIndex(where: {$0.position > board.position}) ?? 0
        self.boards.insert(board, at: insertIndex)
        return insertIndex
    }
    
    mutating func removeBoard(index:Int) {
        self.boards.remove(at: index)
    }
    
    
    mutating func swapBoard(from:Int,to:Int) -> Board {
        var fromBoard = self.boards[from]
        self.boards.remove(at: from)
        
        fromBoard.position = calcSort(toRow: to, boards: self.boards)
        self.boards.insert(fromBoard, at: to)
        return fromBoard
    }
    
    private func calcSort(toRow:Int,boards:[Board])->Double {
        if boards.count == 0 {
            return 65536
        }
        if toRow == 0 {
            return boards[toRow].position / 2
        }
        if toRow == boards.count {
            return  boards[toRow-1].position + 65536
        }
        return (boards[toRow-1].position + boards[toRow].position)/2
    }
}
