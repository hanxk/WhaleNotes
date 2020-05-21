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
    private(set) var database:Realm!
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
    
    func getAllNotes() -> Results<Note> {
        let notes = database.objects(Note.self).sorted(byKeyPath: "createAt")
        return notes
    }
    
    func deleteNote( _ note: Note) {
        try! database.write {
            Logger.info("delete note",note.id)
            database.delete(note)
        }
    }
    
    func addNote( _ note: Note) {
        try! database.write {
            Logger.info("add note",note.id)
            database.add(note)
        }
    }
    
    
    func update(note:Note,withoutNotifying: [NotificationToken]=[],callback:()->Void) {
        try! database.write(withoutNotifying: withoutNotifying) {
            Logger.info("update")
            // 更新时间
            note.updateAt = Date()
            callback()
        }
    }
    
  
    
//    func update(withoutNotifying: [NotificationToken]=[],callback:()->Void) {
//        try! database.write(withoutNotifying: withoutNotifying) {
//            Logger.info("update")
//            callback()
//        }
//    }
}
