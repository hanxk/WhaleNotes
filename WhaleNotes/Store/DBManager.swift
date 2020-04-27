//
//  DBManager.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/4/25.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import RealmSwift

final class DBManager {
    private var database:Realm!
    static let sharedInstance = DBManager()
    
    private init(){
        do {
            database = try Realm()
            Logger.info("db init")
            print(Realm.Configuration.defaultConfiguration.fileURL!)
        } catch let error as NSError {
            Logger.error(error)
        }
    }
    
    func getNote() {
        
    }
    
    func addNote( _ note: Note) {
        try! database.write {
            database.add(note)
            Logger.info("add note",note.id)
        }
    }
    
    func deleteTodo(_ todo: Todo) {
        try! database.write {
            Logger.info("delete todo",todo.id)
            database.delete(todo)
        }
    }
    
    func update(callback:()->Void) {
        try! database.write {
            callback()
        }
    }
}
