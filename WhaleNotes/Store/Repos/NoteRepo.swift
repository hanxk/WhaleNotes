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


class NoteRepo {
    
    
    static let shared = NoteRepo()
    private init() {}
    
    var disposebag = DisposeBag()
    
    
    func createNewNote(sectionId:String,noteBlock:Block,childBlocks: [Block]) -> Observable<Note> {
        
        Observable<[Block]>.just(childBlocks)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(childBlocks)  -> Note in
                let reuslt =  DBStore.shared.createNote(sectionId: sectionId,noteBlock:noteBlock, childBlocks: childBlocks)
                switch reuslt {
                case .success(let note):
                    return note

                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    func deleteNote(noteId: String) -> Observable<Bool> {
        return Observable<String>.just(noteId)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteId)  -> Bool in
                let result =  DBStore.shared.deleteNoteBlock(noteBlockId: noteId)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    func deleteNotes(noteIds: [String]) -> Observable<Bool> {
        return Observable<[String]>.just(noteIds)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteIds)  -> Bool in
                let result =  DBStore.shared.deleteNoteBlocks(noteBlockIds: noteIds)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    func updateBlock(block:Block) -> Observable<Block> {
        var updatedBlock = block
        updatedBlock.updatedAt = Date()
        return Observable<Block>.create {  observer -> Disposable in
            
            let result = DBStore.shared.updateBlock(block:block)
            switch result {
            case .success(let newBlock):
                observer.onNext(newBlock)
                observer.onCompleted()
            case .failure(let err):
                observer.onError(err)
            }
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
    }
    
    
    func deleteBlock(block:Block) -> Observable<Bool>{
        return Observable<Block>.just(block)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(block)  -> Bool in
                let result =  DBStore.shared.deleteBlock(block: block)
                switch result {
                case .success(let isSuccess):
                    if block.type == BlockType.image.rawValue { //删除图片
                        do {
                            let path =  ImageUtil.sharedInstance.filePath(imageName: block.source)
                            try FileManager.default.removeItem(at:path)
                        } catch let error as NSError {
                            print("Error: \(error.domain)")
                        }
                    }
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    func deleteImageBlocks(noteId:String) -> Observable<Bool>{
        return Observable<String>.just(noteId)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteId)  -> Bool in
                let result =  DBStore.shared.deleteImageBlocks(noteId: noteId)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    func createBlock(block:Block)-> Observable<Block> {
        Observable<Block>.just(block)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(block)  -> Block in
                let result =  DBStore.shared.createBlock(block: block)
                switch result {
                case .success(let block):
                    return block
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    func createRootTodoBlock(noteId:String)-> Observable<[Block]> {
        Observable<String>.just(noteId)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteId)  -> [Block] in
                let result =  DBStore.shared.createRootTodoBlock(noteId: noteId)
                switch result {
                case .success(let blocks):
                    return blocks
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    
    
    func createImageBlocks(noteId:String,images:[TLPHAsset],success:@escaping (([Block])->Void),failed:@escaping()->Void) {
        Observable<[TLPHAsset]>.just(images)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(images)  -> [Block] in
                var imageBlocks:[Block] = []
                images.forEach {
                    if let image =  $0.fullResolutionImage?.fixedOrientation() {
                        let imageName =  $0.uuidName
                        let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
                        if success {
                            let properties:[String:Any] = ["width":image.size.width,"height":image.size.height]
                            imageBlocks.append(Block.newImageBlock(imageUrl: imageName,noteId: noteId,properties:properties))
                        }
                    }
                }
                return imageBlocks
            })
            .map({ (imageBlocks) -> [Block] in
                let result = DBStore.shared.createBlocks(blocks:imageBlocks)
                switch result {
                case .success(let blocks):
                    return blocks
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                success($0)
            }, onError: {
                Logger.error($0)
                failed()
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    func saveImages(images:[TLPHAsset]) ->  Observable<[(String,[String:Any])]> {
        return Observable<[TLPHAsset]>.just(images)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(images)  -> [(String,[String:Any])] in
                var imageBlocks:[(String,[String:Any])] = []
                images.forEach {
                    if let image =  $0.fullResolutionImage?.fixedOrientation() {
                        let imageName =  $0.uuidName
                        let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image: image)
                        if success {
                            let properties:[String:Any] = ["width":image.size.width,"height":image.size.height]
                            imageBlocks.append((imageName,properties))
                        }
                    }
                }
                return imageBlocks
            })
            .observeOn(MainScheduler.instance)
    }
    
    func saveImage(image: UIImage) ->  Observable<(String,[String:Any])> {
        return Observable<UIImage>.just(image)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(image)  -> (String,[String:Any]) in
                let imageName = UUID().uuidString+".png"
                if let rightImage = image.fixedOrientation() {
                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
                    if success {
                        let properties:[String:Any] = ["width":image.size.width,"height":image.size.height]
                        return (imageName,properties)
                    }
                }
                throw DBError(code: .None, message: "createImageBlocks error")
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    
    func createImageBlocks(noteId:String,image: UIImage,success:@escaping ((Block)->Void),failed:@escaping()->Void) {
        Observable<UIImage>.just(image)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(image)  -> Block in
                let imageName = UUID().uuidString+".png"
                if let rightImage = image.fixedOrientation() {
                    let success = ImageUtil.sharedInstance.saveImage(imageName:imageName,image:rightImage )
                    if success {
                        let properties:[String:Any] = ["width":image.size.width,"height":image.size.height]
                        return Block.newImageBlock(imageUrl: imageName,noteId: noteId,properties:properties)
                    }
                }
                throw DBError(code: .None, message: "createImageBlocks error")
            })
            .map({ (imageBlock) -> Block in
                let result = DBStore.shared.createBlock(block: imageBlock)
                switch result {
                case .success(let blocks):
                    return blocks
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                success($0)
            }, onError: {
                Logger.error($0)
                failed()
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
//    func updateNoteBoards(note:Note,boards:[Board]) -> Observable<Note> {
//        return Observable<Note>.create {  observer -> Disposable in
//            let result = DBStore.shared.updateNoteBoards(note:note,boards:boards)
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
    
    func moveNote2Board(note:Note,board:Board) -> Observable<Note>  {
        return Observable<Note>.create {  observer -> Disposable in
            let result = DBStore.shared.moveNote2Board(note:note,board: board)
            switch result {
            case .success(let newBlock):
                observer.onNext(newBlock)
                observer.onCompleted()
            case .failure(let err):
                observer.onError(err)
            }
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
    }
    
}


//MARK: 废纸篓
extension NoteRepo {
    
}

extension NoteRepo {
    
    func getNotesByBoardId(_ boardId:String,noteBlockStatus: NoteBlockStatus) -> Observable<[Note]> {
        return Observable<String>.just(boardId)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteId)  -> [Note] in
                let result =  DBStore.shared.getNotesByBoardId2(boardId, noteBlockStatus: noteBlockStatus)
                switch result {
                case .success(let notes):
                    return notes
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
    
    func searchNotes(keyword:String) -> Observable<[Note]> {
        return Observable<String>.just(keyword)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(keyword)  -> [Note] in
                let result =  DBStore.shared.searchNotes(keyword: keyword)
                switch result {
                case .success(let notes):
                    return notes
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
    }
    
}
