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

class CardEditorViewModel {
    private(set) var blockInfo: BlockInfo
    public let noteInfoPub: PublishSubject<EditorUpdateEvent> = PublishSubject()
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
