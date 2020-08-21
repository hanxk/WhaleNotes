//
//  CardEditorViewModel.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/18.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RxSwift


enum EditorUpdateEvent {
    case updated(block:BlockInfo)
    case statusChanged(block:BlockInfo)
    case backgroundChanged(block:BlockInfo)
    case moved(block:BlockInfo,boardBlock:BlockInfo)
    case delete(block:BlockInfo)
}


enum ContentUpdateEvent {
    case insterted(content:BlockInfo)
    case deleted(content:BlockInfo)
    case updated(content:BlockInfo)
}

class CardEditorViewModel {
    private(set) var blockInfo: BlockInfo
    private var contents:[BlockInfo] {
        get { return blockInfo.contents}
        set { blockInfo.contents = newValue}
    }
    
    public let noteInfoPub: PublishSubject<EditorUpdateEvent> = PublishSubject()
//    public let contentPub: PublishSubject<ContentUpdateEvent> = PublishSubject()
    private let disposable = DisposeBag()
    
    init(blockInfo: BlockInfo) {
        self.blockInfo = blockInfo
    }
    
    func update(block:Block) {
        BlockRepo.shared.updateBlock(block: block, ownerId: blockInfo.ownerId)
            .subscribe {
                self.blockInfo.block = block
                self.noteInfoPub.onNext(.updated(block: self.blockInfo))
            } onError: {
                Logger.error($0)
            }.disposed(by: disposable)
    }
    
    func update(title:String) {
        var block = blockInfo.block
        block.title = title
        self.update(block: block)
    }
}

extension CardEditorViewModel {
    
    func createContent(_ content:BlockInfo,index:Int,callback:(()->Void)? = nil) {
        
        BlockRepo.shared.executeActions(actions:
                                            [
                                                BlockInfoAction.insert(blockInfo: content),
                                                BlockInfoAction.updateForUpdatedAt(id: blockInfo.id)
                                            ]
        )
        .subscribe {
            self.blockInfo.contents.insert(content, at: index)
            self.noteInfoPub.onNext(.updated(block: self.blockInfo))
            callback?()
        } onError: {
            Logger.error($0)
        }.disposed(by: disposable)
    }
    
    func updateContent(_ content:BlockInfo,callback:(()->Void)? = nil) {
        guard let index = self.blockInfo.contents.firstIndex(of: content) else { return }
        if  self.blockInfo.contents[index].block.title == content.title &&
                self.blockInfo.contents[index].blockTodoProperties?.isChecked == content.blockTodoProperties?.isChecked
                {
            return
        }
        
        BlockRepo.shared.executeActions(actions:
                                            [
                                                BlockInfoAction.update(block: content.block),
                                                BlockInfoAction.updateForUpdatedAt(id: blockInfo.id)
                                            ]
        )
        .subscribe {
            self.blockInfo.contents[index] = content
            self.noteInfoPub.onNext(.updated(block: self.blockInfo))
            callback?()
        } onError: {
            Logger.error($0)
        }.disposed(by: disposable)
    }
    
    
    func updatePosition(_ content:BlockInfo,from:Int,to:Int,callback:(()->Void)? = nil) {
//        guard let index = self.blockInfo.contents.firstIndex(of: content) else { return }
        if self.contents[from].id != content.id { return }
        BlockRepo.shared.executeActions(actions:
                                            [
                                                BlockInfoAction.updateForPosition(position: content.blockPosition),
                                                BlockInfoAction.updateForUpdatedAt(id: content.ownerId)
                                            ]
        )
        .subscribe {
            
            self.blockInfo.contents.remove(at: from)
            self.blockInfo.contents.insert(content, at: to)
            
            self.noteInfoPub.onNext(.updated(block: self.blockInfo))
            callback?()
        } onError: {
            Logger.error($0)
        }.disposed(by: disposable)
    }
    
    func deleteContent(_ content:BlockInfo,callback:(()->Void)? = nil) {
        guard let index = self.blockInfo.contents.firstIndex(of: content) else { return }
        
        BlockRepo.shared.executeActions(actions:[
            BlockInfoAction.delete(blockInfo: content),
            BlockInfoAction.updateForUpdatedAt(id: blockInfo.id)
        ]
        )
        .subscribe {
            self.blockInfo.contents.remove(at: index)
            self.noteInfoPub.onNext(.updated(block: self.blockInfo))
            callback?()
        } onError: {
            Logger.error($0)
        }.disposed(by: disposable)
    }
    
    func updateContentAndInsertNew(_ content:BlockInfo,newContent:BlockInfo,newIndex:Int,callback:(()->Void)? = nil) {
        guard let index = self.blockInfo.contents.firstIndex(of: content) else { return }
        
        
        BlockRepo.shared.executeActions(actions: [
            BlockInfoAction.update(block: content.block),
            BlockInfoAction.insert(blockInfo: newContent)
        ])
        .subscribe {
            self.blockInfo.contents[index] = content
            self.blockInfo.contents.insert(newContent, at: newIndex)
            callback?()
        } onError: {
            Logger.error($0)
        }.disposed(by: disposable)
    }
}
