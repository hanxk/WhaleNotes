//
//  NoteUseCase.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/26.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift
import TLPhotoPicker

class NoteRepo:BaseRepo {
    static let shared = NoteRepo()
    private override init() { }
}

extension NoteRepo {
    
    func createNote(noteInfo:BlockInfo) -> Observable<NoteInfo> {
        return Observable<NoteInfo>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> NoteInfo in
                try self.insertBlockInfo(blockInfo: noteInfo)
                return NoteInfo(noteBlock: noteInfo)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func createBlockInfo(blockInfo:BlockInfo,updatedAtId:String? = nil) -> Observable<BlockInfo> {
        return self.createBlockInfo(blockInfos: [blockInfo],updatedAtId: updatedAtId)
            .flatMap {
                return Observable.of($0[0])
            }
    }
    
    func deleteBlockInfo(blockId:String) -> Observable<Bool>{
        return BlockRepo.shared.deleteBlockInfo(blockId: blockId, includeChild: true)
    }
    
    func deleteNote(noteId:String,noteFiles:[String] = []) -> Observable<Void>{
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                if noteFiles.isNotEmpty { //删除附件
                    try ImageUtil.sharedInstance.deleteImages(imageNames: noteFiles)
                }
                // 删除 position
                try self.blockPositionDao.delete(blockId: noteId,includeChild: true)
                // 删除
                try self.blockDao.delete(id: noteId, includeChild: true)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func createBlockInfo(blockInfos:[BlockInfo],updatedAtId:String? = nil) -> Observable<[BlockInfo]> {
        return Observable<[BlockInfo]>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> [BlockInfo] in
                for blockInfo in blockInfos {
                    try self.insertBlockInfo(blockInfo: blockInfo)
                }
                if let updatedAtId = updatedAtId {
                    try self.blockDao.updateUpdatedAt(id: updatedAtId)
                }else {
                    try self.blockDao.updateUpdatedAt(id: blockInfos[0].block.parentId)
                }
                return blockInfos
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func queryNotes(boardId:String,noteStatus:NoteBlockStatus) -> Observable<[NoteInfo]> {
        return Observable<[NoteInfo]>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> [NoteInfo] in
                let blockInfos:[NoteInfo] = try self.blockDao.queryNotes(boardId: boardId,status: noteStatus.rawValue)
                return blockInfos
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func queryTrashNotes() -> Observable<([String:BlockInfo],[NoteInfo])> {
        return Observable<([String:BlockInfo],[NoteInfo])>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> ([String:BlockInfo],[NoteInfo]) in
                let blockInfos:[NoteInfo] = try self.blockDao.queryNotes(status: NoteBlockStatus.trash.rawValue)
                
                let boardIds = blockInfos.map { $0.noteBlock.blockPosition.ownerId }
                // 查询 baord block
                let boardsMap = try self.blockDao.queryBlockInfos(ids: boardIds).reduce(into: [String: BlockInfo]()) {
                    $0[$1.id] = $1
                }
                return (boardsMap,blockInfos)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    func deleteTrashNotes() -> Observable<Void> {
        return Observable<Void>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Void in
                
                let images = try self.blockDao.queryNotesImages(status: .trash)
                if images.isNotEmpty { //删除图片
                    try ImageUtil.sharedInstance.deleteImages(imageNames: images)
                }
                
                
                // 删除 position
                try self.blockPositionDao.delete(noteStatus: .trash)
                
                try self.blockDao.deleteNotes(status: .trash)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func searchNotes(keyword:String) -> Observable<([String:BlockInfo],[NoteInfo])> {
        return Observable<([String:BlockInfo],[NoteInfo])>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> ([String:BlockInfo],[NoteInfo]) in
                let blockInfos:[NoteInfo] = try self.blockDao.queryNotes(keyword: keyword)
                
                let boardIds = blockInfos.map { $0.noteBlock.blockPosition.ownerId }
                // 查询 baord block
                let boardsMap = try self.blockDao.queryBlockInfos(ids: boardIds).reduce(into: [String: BlockInfo]()) {
                    $0[$1.id] = $1
                }
                return (boardsMap,blockInfos)
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    private func insertBlockInfo(blockInfo:BlockInfo) throws {
        try self.blockDao.insert(blockInfo.block)
        try self.blockPositionDao.insert(blockInfo.blockPosition)
        
        for contentBlockInfo in blockInfo.contentBlocks {
            try insertBlockInfo(blockInfo: contentBlockInfo)
        }
    }
    
    
    func updatePosition(blockPosition:BlockPosition,noteId:String) -> Observable<Bool> {
        return Observable<Bool>.create { [self]  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                try blockPositionDao.update(blockPosition)
                try blockDao.updateUpdatedAt(id: noteId)
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    
    func moveToBoard(note:BlockInfo,boardId:String) -> Observable<BlockInfo> {
        return Observable<BlockInfo>.create { [self]  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> BlockInfo in
                // 获取 boardId 中最小的 position
                var position:Double
                if let minPosition =  try blockPositionDao.queryMinPosition(id: boardId)?.position {
                    position = minPosition / 2
                }else {
                    position = BlockConstants.position
                }
                
                var newNote = note
                newNote.block.parentId = boardId
                newNote.updatedAt = Date()
                
                // 更新 parent id
                try blockDao.updateParentId(id: note.id, newParentId: boardId)
                
                
                // 更新 position
                var newPos = note.blockPosition
                newPos.ownerId = boardId
                newPos.position = position
                try blockPositionDao.update(newPos)
                
                newNote.blockPosition = newPos
                
                return newNote
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}


extension NoteRepo {
    
    func updateTitle(id:String ,title:String,updatedTimeBlockId:String? = nil) -> Observable<Bool> {
        return self.updateNoteStatus(id: id, keyValue: ("title", title),updatedTimeBlockId:updatedTimeBlockId)
    }
    
    func updateNoteStatus(id:String ,status:NoteBlockStatus,updatedTimeBlockId:String? = nil) -> Observable<Bool> {
        return self.updateNoteStatus(id: id, keyValue: ("status", status.rawValue),updatedTimeBlockId:updatedTimeBlockId)
    }
    
    func updateNoteBackgroundColor(id:String ,backgroundColor:String,updatedTimeBlockId:String? = nil) -> Observable<Bool> {
        return self.updateNoteStatus(id: id, keyValue: ("backgroundColor", backgroundColor),updatedTimeBlockId:updatedTimeBlockId)
    }
    
    func updateProperties(id:String ,properties:Codable ,updatedTimeBlockId:String? = nil) -> Observable<Bool> {
        return Observable<Bool>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                try self.blockDao.updateProperties(id: id,propertiesJSON: json(from: properties)!)
                if let updatedTimeBlockId = updatedTimeBlockId {
                    try self.blockDao.updateUpdatedAt(id: updatedTimeBlockId)
                }
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
    
    private func updateNoteStatus(id:String ,keyValue:(String,Any) ,updatedTimeBlockId:String? = nil) -> Observable<Bool> {
        return Observable<Bool>.create {  observer -> Disposable in
            self.transactionTask(observable: observer) { () -> Bool in
                try self.blockDao.updateProperties(id: id, keyValue:keyValue)
                if let updatedTimeBlockId = updatedTimeBlockId {
                    try self.blockDao.updateUpdatedAt(id: updatedTimeBlockId)
                }
                return true
            }
        }
        .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
        .observeOn(MainScheduler.instance)
    }
}

extension NoteRepo {
    
    func createNote(images:[TLPHAsset],parentId:String,position:Double) ->  Observable<NoteInfo> {
       return  self.saveImages(images: images)
            .map { images ->  BlockInfo in
                var noteInfo = Block.note(title: "", parentId: parentId, position: position)
                var position:Double = 0
                let imageBlocks:[BlockInfo] = images.map {
                    position += 65536
                    return Block.image(parent: noteInfo.id, properties: $0, position: position)
                }
                noteInfo.contentBlocks.append(contentsOf:imageBlocks)
                return noteInfo
            }
            .flatMap(self.createNote)
    
    }
    
    func saveImages(images:[TLPHAsset]) ->  Observable<[BlockImageProperty]> {
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
                return BlockImageProperty(url: imageName, width: Float(image.size.width), height: Float(image.size.height))
            }
            .filter { $0 != nil }
            .map{ return $0! }
            .toArray()
            .asObservable()
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .observeOn(MainScheduler.instance)
    }
    
    func saveImage(image: UIImage) -> Observable<BlockImageProperty> {
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
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .observeOn(MainScheduler.instance)
    }
}



//    static let shared = NoteRepo()
//    private init() {}
//    
//    var disposebag = DisposeBag()
//    
//    
//    func createNewNote(sectionId:String,noteBlock:Block, childBlocks: [Block]) -> Observable<Note> {
//        
////        Observable<[Block]>.just(childBlocks)
////            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
////            .map({(childBlocks)  -> Note in
////                let reuslt =  DBStore.shared.createNote(sectionId: sectionId,noteBlock:noteBlock,childBlocks: childBlocks)
////                switch reuslt {
////                case .success(let note):
////                    return note
////
////                case .failure(let err):
////                    throw err
////                }
////            })
////            .observeOn(MainScheduler.instance)
//    }
//    
//    func deleteNote(noteId: String) -> Observable<Bool> {
//        return Observable<String>.just(noteId)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(noteId)  -> Bool in
//                let result =  DBStore.shared.deleteNoteBlock(noteBlockId: noteId)
//                switch result {
//                case .success(let isSuccess):
//                    return isSuccess
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//    func deleteNotes(noteIds: [String]) -> Observable<Bool> {
//        return Observable<[String]>.just(noteIds)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(noteIds)  -> Bool in
//                let result =  DBStore.shared.deleteNoteBlocks(noteBlockIds: noteIds)
//                switch result {
//                case .success(let isSuccess):
//                    return isSuccess
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func updateBlock(block:Block) -> Observable<Block> {
//        var updatedBlock = block
//        updatedBlock.updatedAt = Date()
//        return Observable<Block>.create {  observer -> Disposable in
//            
//            let result = DBStore.shared.updateBlock(block:block)
//            switch result {
//            case .success(let newBlock):
//                observer.onNext(newBlock)
//                observer.onCompleted()
//            case .failure(let err):
//                observer.onError(err)
//            }
//            return Disposables.create()
//        }
//        .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func deleteBlock(block:Block) -> Observable<Bool>{
//        return Observable<Block>.just(block)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(block)  -> Bool in
//                let result =  DBStore.shared.deleteBlock(block: block)
//                switch result {
//                case .success(let isSuccess):
//                    if block.type == BlockType.image.rawValue { //删除图片
//                        do {
//                            let path =  ImageUtil.sharedInstance.filePath(imageName: block.blockImageProperties!.url)
//                            try FileManager.default.removeItem(at:path)
//                        } catch let error as NSError {
//                            print("Error: \(error.domain)")
//                        }
//                    }
//                    return isSuccess
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func deleteImageBlocks(noteId:String) -> Observable<Bool>{
//        return Observable<String>.just(noteId)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(noteId)  -> Bool in
//                let result =  DBStore.shared.deleteImageBlocks(noteId: noteId)
//                switch result {
//                case .success(let isSuccess):
//                    return isSuccess
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func createBlock(block:Block)-> Observable<Block> {
//        Observable<Block>.just(block)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(block)  -> Block in
//                let result =  DBStore.shared.createBlock(block: block)
//                switch result {
//                case .success(let block):
//                    return block
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//    
//    func createRootTodoBlock(noteId:String)-> Observable<[Block]> {
//        Observable<String>.just(noteId)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(noteId)  -> [Block] in
//                let result =  DBStore.shared.createRootTodoBlock(noteId: noteId)
//                switch result {
//                case .success(let blocks):
//                    return blocks
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//    func createImageBlocks(noteId:String,images:[TLPHAsset],success:@escaping (([Block])->Void),failed:@escaping()->Void) {
//        self.saveImages(images: images,noteId: noteId)
//            .map({ (imageBlocks) -> [Block] in
//                let result = DBStore.shared.createBlocks(blocks:imageBlocks)
//                switch result {
//                case .success(let blocks):
//                    return blocks
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext:{
//                success($0)
//            }, onError: {
//                Logger.error($0)
//                failed()
//            }, onCompleted: nil, onDisposed: nil)
//            .disposed(by: disposebag)
//    }
//    

//    
//    func saveImage(url:String)-> Observable<String> {
//        return Observable<String>.just(url)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(url)  -> String in
//                guard let imageURL = URL(string: url) else { return "" }
//                let data = try Data(contentsOf: imageURL)
//                guard let image = UIImage(data: data) else { return "" }
//                let imageName = UUID().uuidString+".png"
//                if let rightImage = image.fixedOrientation() {
//                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage)
//                    if success {
//                        return imageName
//                    }
//                }
//                throw DBError(code: .None, message: "createImageBlocks error")
//            })
//            .observeOn(MainScheduler.instance)
//    }
//
//    
//    
//    
//    func createImageBlocks(noteId:String,image: UIImage,success:@escaping ((Block)->Void),failed:@escaping()->Void) {
//        self.saveImage(image: image,noteId: noteId)
//            .map({ (imageBlock) -> Block in
//                let result = DBStore.shared.createBlock(block: imageBlock)
//                switch result {
//                case .success(let blocks):
//                    return blocks
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//            .subscribe(onNext:{
//                success($0)
//            }, onError: {
//                Logger.error($0)
//                failed()
//            }, onCompleted: nil, onDisposed: nil)
//            .disposed(by: disposebag)
//    }
//    
//    //    func updateNoteBoards(note:Note,boards:[Board]) -> Observable<Note> {
//    //        return Observable<Note>.create {  observer -> Disposable in
//    //            let result = DBStore.shared.updateNoteBoards(note:note,boards:boards)
//    //            switch result {
//    //            case .success(let newBlock):
//    //                observer.onNext(newBlock)
//    //                observer.onCompleted()
//    //            case .failure(let err):
//    //                observer.onError(err)
//    //            }
//    //            return Disposables.create()
//    //        }
//    //        .observeOn(MainScheduler.instance)
//    //    }
//    
//    func moveNote2Board(note:Note,board:Board) -> Observable<Note>  {
//        return Observable<Note>.create {  observer -> Disposable in
//            let result = DBStore.shared.moveNote2Board(note:note,board: board)
//            switch result {
//            case .success(let newBlock):
//                observer.onNext(newBlock)
//                observer.onCompleted()
//            case .failure(let err):
//                observer.onError(err)
//            }
//            return Disposables.create()
//        }
//        .observeOn(MainScheduler.instance)
//    }
//    
//}


//MARK: 废纸篓
//extension NoteRepo {
//
//}

//extension NoteRepo {


//    func searchNotes(keyword:String) -> Observable<[NoteAndBoard]> {
//        return Observable<String>.just(keyword)
//            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
//            .map({(keyword)  -> [NoteAndBoard] in
//                let result =  DBStore.shared.searchNotes(keyword: keyword)
//                switch result {
//                case .success(let notes):
//                    return notes
//                case .failure(let err):
//                    throw err
//                }
//            })
//            .observeOn(MainScheduler.instance)
//    }
//    
//}
