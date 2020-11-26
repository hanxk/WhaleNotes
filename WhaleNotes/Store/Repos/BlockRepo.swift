//
//  BaseRepo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/7/12.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift
import TLPhotoPicker

class BlockRepo:BaseRepo {
    static let shared = BlockRepo()
    //    private var spaceDao:SpaceDao {
    //        return DBManager.shared.spaceDao
    //    }
    //
    //    private var blockPositionDao:BlockPositionDao {
    //        return DBManager.shared.blockPositionDao
    //    }
}


extension BlockRepo {
    
}

//MARK: BlockInfo
extension BlockRepo {
    
    func getBlockInfos(ownerId:String,blockType:BlockType,status:BlockStatus = .normal) -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [BlockInfo] in
                let blocks:[BlockInfo] = try self.blockDao.query(ownerId: ownerId, type: blockType.rawValue, status: status.rawValue)
                return blocks
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func getBlockInfos2(ownerId:String,status:BlockStatus = .normal) -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.executeTask(observable: observer) { () -> [BlockInfo] in
                let blocks:[BlockInfo] = try self.blockDao.query(ownerId: ownerId, type: "", status: status.rawValue)
                return blocks
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
//    func getFirstBlockInfo(ownerId:String,status:BlockStatus = .normal) -> Observable<BlockInfo?> {
//        return Observable<[BlockInfo]>.create {  observer -> Disposable in
//            self.executeTask(observable: observer) { () -> [BlockInfo] in
//                let blocks:[BlockInfo] = try self.blockPositionDao.queryMinPosition(id: ownerId)
//                return blocks
//            }
//        }
//        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//        .observeOn(MainScheduler.instance)
//    }
    
    
    func createBlock(_ block:BlockInfo) -> Observable<BlockInfo> {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockInfo in
                try self.insertBlockInfo(block)
                // 添加 content
                for content in block.contents {
                  try self.insertBlockInfo(content)
                }
                return block
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createBlocks(_ blocks:[BlockInfo]) -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> [BlockInfo] in
                for blockInfo in blocks {
                    try self.insertBlockInfo(blockInfo)
                }
                return blocks
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func update(blockPosition:BlockPosition) -> Observable<BlockPosition> {
        return Observable<BlockPosition>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockPosition in
                try self.blockDao.updateUpdatedAt(id: blockPosition.blockId)
                if  blockPosition.ownerId.isNotEmpty {
                    try self.blockDao.updateUpdatedAt(id: blockPosition.ownerId)
                }
                try self.blockPositionDao.update(blockPosition)
                return blockPosition
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func updateBlock(block:Block,ownerId:String) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                try self.blockDao.updateUpdatedAt(id: ownerId)
                try self.blockDao.update(block)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func update(blockInfo:BlockInfo) -> Observable<BlockInfo> {
        return Observable<BlockInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockInfo in
                try self.blockDao.update(blockInfo.block)
                try self.blockPositionDao.update(blockInfo.blockPosition)
                
                let ownerId = blockInfo.blockPosition.ownerId
                if  ownerId.isNotEmpty {
                    try self.blockDao.updateUpdatedAt(id: ownerId)
                }
                return blockInfo
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func executeActions(actions:BlockInfoAction...) -> Observable<Void> {
        return self.executeActions(actions: actions)
    }
    
    func executeActions(actions:[BlockInfoAction]) -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                for action in actions {
                    switch action {
                    case .insert(blockInfo: let blockInfo):
                        try self.insertBlockInfo(blockInfo)
                    case .delete(blockInfo: let blockInfo):
                        try self.deleteBlockInfo(blockInfo)
                    case .update(block: let block):
                        try self.blockDao.update(block)
                    case .updateForUpdatedAt(id: let id):
                        try self.blockDao.updateUpdatedAt(id: id)
                    case .updateForProperties(id: let id, properties: let properties):
                        try self.blockDao.updateProperties(id: id, properties: properties)
                    case .updateForPosition(position: let position):
                        try self.blockPositionDao.update(position)
                    }
                }
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}

enum BlockInfoAction {
    case insert(blockInfo:BlockInfo)
    case delete(blockInfo:BlockInfo)
    case update(block:Block)
    case updateForUpdatedAt(id:String)
    case updateForProperties(id:String,properties:String)
    case updateForPosition(position:BlockPosition)
}

//MARK: image block
extension BlockRepo {
    
    func createImageBlocks(images:[TLPHAsset],ownerId:String) -> Observable<[BlockInfo]>{
        return self.saveImages(images: images, ownerId: ownerId)
            .flatMap {properties in
                return self.createImageBlocks(properties:properties,ownerId:ownerId)
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .observeOn(MainScheduler.instance)
    }
    
    func createImageBlock(image: UIImage,ownerId:String) -> Observable<[BlockInfo]>{
        return self.saveImage(image: image)
            .flatMap {properties in
                return self.createImageBlocks(properties:[properties],ownerId:ownerId)
            }
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .observeOn(MainScheduler.instance)
    }
    
    private func createImageBlocks(properties:[BlockImageProperty],ownerId:String) -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> [BlockInfo] in
                
                var minPostion = try self.blockPositionDao.queryMinPosition(id: ownerId) ?? 65536*2
                minPostion =  minPostion / 2
                
                let imageBlocks:[BlockInfo] =  properties.map {
                    let imageblock =  Block.image(parent: ownerId, properties: $0, position: minPostion)
                    minPostion /= 2
                    return imageblock
                }
                for blockInfo in imageBlocks {
                    try self.insertBlockInfo(blockInfo)
                }
                return imageBlocks
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    private func saveImages(images:[TLPHAsset],ownerId:String) ->  Observable<[BlockImageProperty]> {
        Observable.from(images)
            .map { return ($0.uuidName,$0.fullResolutionImage?.fixedOrientation())}
            .filter { $0.1 != nil}
            .map { nameAndImage -> BlockImageProperty? in
                let imageName = nameAndImage.0
                let image = nameAndImage.1!
                let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
                if !success {
                    return nil
                }
                let properties =  BlockImageProperty(url: imageName, width: Float(image.size.width), height: Float(image.size.height))
                return properties
            }
            .filter { $0 != nil }
            .map{ return $0! }
            .toArray()
            .asObservable()
    }
    
    private func saveImage(image: UIImage) -> Observable<BlockImageProperty> {
        return Observable<UIImage>.just(image)
            .map({(image)  -> BlockImageProperty in
                let imageName = UUID().uuidString+".jpg"
                if let rightImage = image.fixedOrientation() {
                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
                    if success {
                        let pro = BlockImageProperty(url: imageName, width: Float(image.size.width), height: Float(image.size.height))
                        return pro
                    }
                }
                throw DBError(message: "createImageBlocks error")
            })
    }
}

//MARK: 通用方法
extension BlockRepo {
    //    func getBlocks(parentId:String) -> Observable<[Block]> {
    //        return Observable<[Block]>.create {  observer -> Disposable in
    //            self.executeTask(observable: observer) { () -> [Block] in
    //                let blocks:[Block] = try self.blockDao.query(parentId: parentId)
    //                return blocks
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    
    //    func createBlock(_ blockInfo:BlockInfo) -> Observable<Bool> {
    //        return Observable<Bool>.create {  observer -> Disposable in
    //            self.transactionTask(observable: observer) { () -> Bool in
    //                try self.blockDao.insert(blockInfo.block)
    //                try self.blockPositionDao.insert(blockInfo.blockPosition)
    //                return true
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    
    //    func createBlock(_ block:Block,parent:Block) -> Observable<(Block,Block)> {
    //        return Observable<(Block,Block)>.create {  observer -> Disposable in
    //            self.transactionTask(observable: observer) { () -> (Block,Block) in
    //                
    //                if block.parentId != parent.id || !parent.content.contains(block.id) {
    //                    throw DBError(message: "parent error")
    //                }
    //                try self.blockDao.insert(block)
    //                // 更新 parent content
    //                try self.blockDao.updateBlock(block: parent)
    //                return (block,parent)
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    
    //    func createBlock(_ block:Block,parent:Space) -> Observable<(Block,Space)> {
    //        return Observable<(Block,Space)>.create {  observer -> Disposable in
    //            
    //            self.transactionTask(observable: observer) { () -> (Block,Space) in
    ////                if block.parentId != parent.id || !parent.boardGroupIds.contains(block.id) {
    ////                    throw DBError(message: "parent error")
    ////                }
    //                try self.blockDao.insert(block)
    ////                try self.spaceDao.update(boardGroupIds: parent.boardGroupIds)
    //                return (block,parent)
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    
    //    func updateBlock(_ block:Block) -> Observable<Block> {
    //        return Observable<Block>.create {  observer -> Disposable in
    //            self.executeTask(observable: observer) { () -> Block in
    //                try self.blockDao.updateBlock(block: block)
    //                return block
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    func updateProperties(id:String,propertiesJSON:String) -> Observable<String> {
    //        return Observable<String>.create {  observer -> Disposable in
    //            self.executeTask(observable: observer) { () -> String in
    //                try self.blockDao.updateProperties(id: id, propertiesJSON: propertiesJSON)
    //                return id
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    func updateContent(id:String,content:[String]) -> Observable<String> {
    //        return Observable<String>.create {  observer -> Disposable in
    //            self.executeTask(observable: observer) { () -> String in
    //                try self.blockDao.updateContent(id: id, content: content)
    //                return id
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    //    
    //    
    //    func deleteBlockInfo(blockId:String,includeChild:Bool) -> Observable<Bool> {
    //        return Observable<Bool>.create {  observer -> Disposable in
    //            self.transactionTask(observable: observer) { () -> Bool in
    //                // 删除 position
    //                try self.blockPositionDao.delete(blockId: blockId,includeChild: includeChild)
    //                // 删除
    //                try self.blockDao.delete(id: blockId, includeChild: includeChild)
    //                return true
    //            }
    //        }
    //        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
    //        .observeOn(MainScheduler.instance)
    //    }
    
}
