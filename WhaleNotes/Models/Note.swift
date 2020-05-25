//
//  Note.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/20.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import  RealmSwift

class Note: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var createAt: Date = Date()
    @objc dynamic var updateAt: Date = Date()
    
    @objc dynamic var titleBlock: Block? = nil
    @objc dynamic var textBlock: Block? = nil
    // -1: 删除, 1: 正常
    @objc dynamic var status:Int = 1
    
    let todoBlocks  = List<Block> ()
    
    // 附件： image, video, link
    let attachBlocks =  List<Block>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    var isEmpty:Bool {
        return titleBlock?.text.isEmpty ?? true &&
        textBlock?.text.isEmpty ?? true &&
        todoBlocks.isEmpty &&
        attachBlocks.isEmpty
    }
}
