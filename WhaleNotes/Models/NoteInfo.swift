//
//  NoteInfo.swift
//  WhaleNotes
//
//  Created by hanxk on 2020/12/14.
//  Copyright © 2020 hanxk. All rights reserved.
//

import Foundation
import DeepDiff
import CloudKit

struct NoteInfo {
    var note:Note
    var tags:[Tag] = []
}


extension NoteInfo {
    var id:String {
        return self.note.id
    }
    var title:String {
        return self.note.title
    }
    var content:String {
        return self.note.content
    }
    var createdAt:Date {
        return self.note.createdAt
    }
    var updatedAt:Date {
        return self.note.updatedAt
    }
    var status:NoteStatus {
        get { return note.status }
        set { self.note.status = newValue }
    }
    
    var isEmpty:Bool {
        return note.title.isEmpty && note.content.isEmpty
        && (tags.count <=  1)
    }
}

extension NoteInfo:DiffAware {
    
    typealias DiffId = String
    var diffId: DiffId { return self.id }
    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        (a.id == b.id) && (a.note.updatedAt  ==  b.note.updatedAt) 
    }
}


extension NoteInfo {
    
    static func from(from record: CKRecord) -> NoteInfo? {
//        let note = Note.from(from: record)
        return nil
       
//        let title = record["title"] as? String ?? ""
//        let content = record["content"] as? String ?? ""
//        guard
//            let id = record["id"] as? String,
//            let status = record["status"] as? Int,
//            let createdAt = record["createdAt"] as? Date,
//            let updatedAt = record["updatedAt"] as? Date
//        else { return nil }
//        guard let noteStatus = NoteStatus.init(rawValue: status) else { return nil }
//        let note = Note(id: id, title: title, content: content, status: noteStatus,createdAt: createdAt, updatedAt: updatedAt)
//        let noteInfo = NoteInfo(note: note)
//        return noteInfo
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Note",recordID: self.recordID)
        record["id"] = self.id as CKRecordValue
        record["title"] = self.title as CKRecordValue
        record["content"] = self.content as CKRecordValue
        record["status"] = self.status.rawValue as CKRecordValue
        record["createdAt"] = self.createdAt as CKRecordValue
        record["updatedAt"] = self.updatedAt as CKRecordValue
        record["tags"] = self.tags.map {CKRecord.Reference(recordID: $0.recordID, action: .none) }
        return record
    }
    
    var recordID: CKRecord.ID {
        return CKRecord.ID(recordName: id, zoneID: NotesSyncEngine.shared.zone.zoneID)
    }
}
