//
//  Tag.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import DeepDiff
import CloudKit

struct Tag:DiffAware {
    
    var id:String = UUID.init().uuidString
    var title:String = ""
    var icon:String = ""
    var createdAt:Date!
    var updatedAt:Date!
    
    // 标识是否需要同步，默认未false，（该字段不会上传到iCloud）
    var isDel:Bool = false
    
    init() {
        let date =  Date()
        self.createdAt = date
        self.updatedAt = date
    }
    
    init(id:String = UUID.init().uuidString,title:String,icon:String="",isDel:Bool = false,createdAt:Date,updatedAt:Date) {
        self.id = id
        self.icon = icon
        self.title = title
        self.isDel = isDel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    

    typealias DiffId = String
    var diffId: DiffId { return self.id }
    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        (a.id == b.id) && (a.updatedAt  ==  b.updatedAt)
    }
}

extension Tag:SQLTable {
    static var createStatement: String {
        return  """
                CREATE TABLE IF NOT EXISTS "tag" (
                  "id" TEXT PRIMARY KEY NOT NULL,
                  "title" TEXT UNIQUE NOT NULL,
                  "icon" TEXT NOT NULL,
                  "is_del" INTEGER DEFAULT 0,
                  "created_at" TIMESTAMP,
                  "updated_at" TIMESTAMP
                );
        """
    }
}
extension Tag {
    static func from(from record: CKRecord) -> Tag? {
        let icon = record["icon"] as? String ?? ""
        guard
            let id = record["id"] as? String,
            let title = record["title"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        let tag = Tag(id: id, title: title, icon: icon, createdAt: createdAt, updatedAt: updatedAt)
        return tag
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Tag",recordID: self.recordID)
        record["id"] = self.id as CKRecordValue
        record["title"] = self.title as CKRecordValue
        record["icon"] = self.icon as CKRecordValue
        record["createdAt"] = self.createdAt as CKRecordValue
        record["updatedAt"] = self.updatedAt as CKRecordValue
        return record
    }
    
    
    var recordID: CKRecord.ID {
        return CKRecord.ID(recordName: id, zoneID: NotesSyncEngine.shared.zone.zoneID)
    }
}
