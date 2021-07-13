//
//  Note.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import CloudKit

struct Note {
    var id:String = UUID.init().uuidString
    var title:String = ""
    var content:String = ""
    var status:NoteStatus =  .normal
    var createdAt:Date!
    var updatedAt:Date!
    
    var isDel:Bool = false
    // 本地数据，还未同步（该字段不会上传到iCloud）
    var isLocal:Bool = true
    
    init() {
        let date =  Date()
        self.createdAt = date
        self.updatedAt = date
    }
    
    init(id:String,title:String,content:String,status:NoteStatus = .normal,isDel:Bool = false,isLocal:Bool = true,createdAt:Date,updatedAt:Date) {
        self.id = id
        self.title = title
        self.content = content
        self.status = status
        self.isDel = isDel
        self.isLocal = isLocal
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}


enum NoteStatus: Int,Codable {
    case trash = -1
    case normal = 1
    case archive = 2
}
enum ChangedType: Int,Codable {
    case none = 0
    case update = 1
    case delete = 2
}


extension Note:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "note" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "title" TEXT,
                      "content" TEXT,
                      "status" INTEGER,
                      "is_del" INTEGER DEFAULT 0,
                      "is_local" INTEGER DEFAULT 1,
                      "created_at" TIMESTAMP,
                      "updated_at" TIMESTAMP
                    );
        """
    }
}

extension Note {
    static func from(from record: CKRecord) -> Note? {
        let title = record["title"] as? String ?? ""
        let content = record["content"] as? String ?? ""
        guard
            let id = record["id"] as? String,
            let status = record["status"] as? Int,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else { return nil }
        guard let noteStatus = NoteStatus.init(rawValue: status) else { return nil }
        let note = Note(id: id, title: title, content: content, status: noteStatus,isLocal: false,createdAt: createdAt, updatedAt: updatedAt)
        return note
    }
//    static func from(from record: CKRecord) -> (Note,[String])? {
//        let title = record["title"] as? String ?? ""
//        let content = record["content"] as? String ?? ""
//        guard
//            let id = record["id"] as? String,
//            let status = record["status"] as? Int,
//            let createdAt = record["createdAt"] as? Date,
//            let updatedAt = record["updatedAt"] as? Date
//        else { return nil }
//        let tagIDs:[String] = (record["tags"] as? [String]) ?? []
//        guard let noteStatus = NoteStatus.init(rawValue: status) else { return nil }
//        let note = Note(id: id, title: title, content: content, status: noteStatus,createdAt: createdAt, updatedAt: updatedAt)
//        return (note,tagIDs)
//    }
    
    func toRecord(noteFiles:[NoteFile] = []) -> CKRecord {
        let record = CKRecord(recordType: "Note",recordID: self.recordID)
        record["id"] = self.id as CKRecordValue
        record["title"] = self.title as CKRecordValue
        record["content"] = self.content as CKRecordValue
        record["status"] = self.status.rawValue as CKRecordValue
        record["createdAt"] = self.createdAt as CKRecordValue
        record["updatedAt"] = self.updatedAt as CKRecordValue
        
//        if noteFiles.isNotEmpty {
//            let noteFileReferences:[CKRecord.Reference] = noteFiles.map { $0.toRecord2() }.map { CKRecord.Reference(record: $0, action: .deleteSelf) }
//            record["files"] = noteFileReferences as CKRecordValue
//        }
        
        return record
    }
    
    var recordID: CKRecord.ID {
        return CKRecord.ID(recordName: id, zoneID: NotesSyncEngine.shared.zone.zoneID)
    }
}
