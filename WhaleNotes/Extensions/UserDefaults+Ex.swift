//
//  UserDefaults+Ex.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/4/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import CloudKit

extension UserDefaults {
    
    public subscript(key: String) -> AnyObject? {
        get {
            return object(forKey: key) as AnyObject?
        }
        set {
            set(newValue, forKey: key)
        }
    }
    
    public func date(forKey key: String) -> Date? {
        return object(forKey: key) as? Date
    }
}
