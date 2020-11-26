//
//  BoardsRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/15.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift

class BoardsRepo:BaseRepo {
    static let shared = BoardsRepo()
}


extension BoardsRepo {
    func getBoards() -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> [BlockInfo] in
                let blocks:[BlockInfo] = try self.blockDao.query(ownerId: "", type: BlockType.board.rawValue, status: BlockStatus.normal.rawValue)
                if blocks.isNotEmpty {
                    return blocks
                }
                // 新增 collect board
                let property = BlockBoardProperty(icon: "", type: .collect)
                var collectBoard = Block.board(title: "collect", properties: property, position: 65536*2)
                try self.insertBlockInfo(collectBoard)
                collectBoard.block =  Block.convert2LocalSystemBoard(board: collectBoard.block)
                return [collectBoard]
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func createBoard(icon:String,title:String) -> Observable<BlockInfo> {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockInfo in
                
                // 获取 first position
                var minPos:Double
                if let minPosition = try self.blockPositionDao.queryMinPosition(id: "") {
                    minPos = minPosition / 2
                }else {
                    minPos = 65536
                }
                
                let board = Block.board(title: title, properties: BlockBoardProperty(icon: icon, type: .user), position: minPos)
                try self.insertBlockInfo(board)
                return board
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func moveCard2NewBoard(card:BlockInfo,newBoard:BlockInfo) -> Observable<BlockInfo> {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockInfo in
                
                // 获取 first position
                let boardId = newBoard.id
                var newPos:Double
                if let minPosition = try self.blockPositionDao.queryMinPosition(id: newBoard.id) {
                    newPos = minPosition / 2
                }else {
                    newPos = 65536
                }
                let newPosition = BlockPosition(blockId: card.id, ownerId: boardId, position: newPos)
                //删除旧的position
                try self.blockPositionDao.delete(card.blockPosition.id)
                //更新position
                try self.blockPositionDao.insert(newPosition)
                try self.blockDao.updateUpdatedAt(id: card.id)
                
                var newCard = card
                newCard.blockPosition = newPosition
                return newCard
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
}
