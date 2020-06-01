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


class EditorUseCase {
    
    var disposebag = DisposeBag()
    
    func deleteNote(noteId: Int64,callback:@escaping (Bool)->Void) {
        Observable<Int64>.just(noteId)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(noteId)  -> Bool in
                let result =  DBStore.shared.deleteNote(id: noteId)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                callback($0)
            }, onError: { err in
                Logger.error(err)
            }, onCompleted: {
                
            }, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    
    func updateBlock(block:Block,callback:@escaping (Bool)->Void) {
        Observable<Bool>.create {  observer -> Disposable in
            let result = DBStore.shared.updateBlock(block:block)
            switch result {
            case .success(let isSuccess):
                observer.onNext(isSuccess)
                observer.onCompleted()
            case .failure(let err):
                observer.onError(err)
            }
            return Disposables.create()
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: {
            callback($0)
        }, onError: {
            Logger.error($0)
        }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    func deleteBlock(block:Block,callback:@escaping (Bool)->Void) {
        Observable<Block>.just(block)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(block)  -> Bool in
                let result =  DBStore.shared.deleteBlock(block: block)
                switch result {
                case .success(let isSuccess):
                    return isSuccess
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    func createBlock(block:Block,callback:@escaping (Block)->Void) {
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
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    func createBlockInfo(blockInfo:BlockInfo,callback:@escaping (BlockInfo)->Void) {
        Observable<BlockInfo>.just(blockInfo)
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .map({(blockInfo)  -> BlockInfo in
                let result =  DBStore.shared.createBlockInfo(blockInfo: blockInfo)
                switch result {
                case .success(let newBlockInfo):
                    return newBlockInfo
                case .failure(let err):
                    throw err
                }
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    
    func updateAndInsertBlock(updatedBlock:Block,insertedblock:Block,callback:@escaping (Block)->Void) {
        Observable<Block>.create {  observer -> Disposable in
                let result = DBStore.shared.updateAndInsertBlock(updatedBlock: updatedBlock, insertedBlock: insertedblock)
                switch result {
                case .success(let insertedBlock):
                    observer.onNext(insertedBlock)
                    observer.onCompleted()
                case .failure(let err):
                    observer.onError(err)
                }
                return Disposables.create()
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext:{
                callback($0)
            }, onError: {
                Logger.error($0)
            }, onCompleted: nil, onDisposed: nil)
            .disposed(by: disposebag)
    }
    
    func createImageBlocks(noteId:Int64,images:[TLPHAsset],success:@escaping (([Block])->Void),failed:@escaping()->Void) {
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
    
    func createImageBlocks(noteId:Int64,image: UIImage,success:@escaping ((Block)->Void),failed:@escaping()->Void) {
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
    
}