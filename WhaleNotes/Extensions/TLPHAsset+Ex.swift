//
//  TLPHAsset+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/5/2.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import TLPhotoPicker

extension TLPHAsset {
    var uuidName:String {
        get {
            let type = extType().rawValue
            return UUID().uuidString + "." + type
        }
    }
}
