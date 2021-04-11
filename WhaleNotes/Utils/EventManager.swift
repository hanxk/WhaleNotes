//
//  EventManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/8/16.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation

class EventManager {
    static let shared = EventManager()
    private init() {}
    
    func post(name aName: NSNotification.Name,object:Any? = nil,
       userInfo aUserInfo: [AnyHashable : Any]? = nil) {
        NotificationCenter.default.post(name: aName, object: object, userInfo: aUserInfo)
    }
    
    func addObserver(observer:Any,selector:Selector,name:NSNotification.Name) {
        NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: nil)
    }
    
    func removeObserver(observer:Any) {
        NotificationCenter.default.removeObserver(observer)
    }
}



extension Notification.Name {
    static let Tag_CHANGED
                = NSNotification.Name("Tag_CHANGED")
    static let Tag_DELETED
                = NSNotification.Name("Tag_DELETED")
}

extension Notification.Name {
    static let REMOTE_DATA_CHANGED
                = NSNotification.Name("REMOTE_DATA_CHANGED")
}
