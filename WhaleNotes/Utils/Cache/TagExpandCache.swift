//
//  TagCache.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/22.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import Cache

class  TagExpandCache {
    
    static let shared = TagExpandCache()
    private let storage:Storage<String>!
    
    private init(){
        let diskConfig = DiskConfig(name: "TagExpand")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 100, totalCostLimit: 10)

        let storage = try? Storage(
          diskConfig: diskConfig,
          memoryConfig: memoryConfig,
          transformer: TransformerFactory.forCodable(ofType: String.self) // Storage<String, User>
        )
        self.storage = storage
    }
    
    func set(key:String,value:String) {
        try? self.storage.setObject(value, forKey: key)
    }
    
    func get(key:String)  -> String? {
       return try? self.storage.object(forKey: key)
    }
    
    func remove(key:String) {
        try? self.storage.removeObject(forKey: key)
    }
}
