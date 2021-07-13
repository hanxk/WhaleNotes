//
//  NoteFile.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/7/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit
import DeepDiff
import CloudKit

struct NoteFile {
    var id:String = UUID.init().uuidString
    var name:String
    var noteId:String
    var width:Double
    var height:Double
    var size:Int
    var sort:Int
    var suffix:String
    var createdAt:Date
    var updatedAt:Date
    
    
    var localURL:URL {
        return LocalFileUtil.shared.getFilePathURL(fileId: id, fileName: name)
    }
}
extension NoteFile:DiffAware {
    typealias DiffId = String
    var diffId: DiffId { return self.id }
    static func compareContent(_ a: Self, _ b: Self) -> Bool {
        (a.id == b.id)
    }
}

enum NoteFiletype:Int {
    case photo = 1
    case video = 2
}

extension NoteFile:SQLTable {
    static var createStatement: String {
        return  """
                    CREATE TABLE IF NOT EXISTS "note_file" (
                      "id" TEXT PRIMARY KEY NOT NULL,
                      "name" TEXT,
                      "note_id" TEXT,
                      "width" double,
                      "height" double,
                      "size" INTEGER,
                      "suffix" TEXT,
                      "sort" INTEGER,
                      "created_at" TIMESTAMP,
                      "updated_at" TIMESTAMP
                    );
        """
    }
}

extension NoteFile {
    
    var recordID: CKRecord.ID {
        return CKRecord.ID(recordName: id, zoneID: NotesSyncEngine.shared.zone.zoneID)
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: RecordEntityType.file.rawValue,recordID: self.recordID)
        record["id"] = self.id as CKRecordValue
        record["name"] = self.name as CKRecordValue
        record["noteId"] = self.noteId as CKRecordValue
        record["width"] = self.width as CKRecordValue
        record["height"] = self.height as CKRecordValue
        record["size"] = self.size as CKRecordValue
        record["sort"] = self.sort as CKRecordValue
        record["suffix"] = self.suffix as CKRecordValue
        record["createdAt"] = self.createdAt as CKRecordValue
        record["updatedAt"] = self.updatedAt as CKRecordValue
        
        let asset = CKAsset(fileURL: localURL)
        record["asset"] = asset
        
        let noteRecord = CKRecord(recordType: RecordEntityType.note.rawValue,
                                  recordID: CKRecord.ID(recordName:self.noteId, zoneID: NotesSyncEngine.shared.zone.zoneID))
        let noteRef = CKRecord.Reference(record:noteRecord, action: .deleteSelf)
        record["noteRef"] = noteRef as CKRecordValue
        
        return record
    }
    
    static func from(from record: CKRecord) -> NoteFile? {
        let suffix = (record["suffix"] as? String) ?? ""
        guard
            let id = record["id"] as? String,
            let name = record["name"] as? String,
            let noteId = record["noteId"] as? String,
            let width = record["width"] as? Double,
            let height = record["height"] as? Double,
            let size = record["size"] as? Int,
            let sort = record["sort"] as? Int,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
            
        }
        let noteFile = NoteFile(id: id, name: name, noteId: noteId, width: width, height: height, size: size, sort: sort, suffix: suffix, createdAt: createdAt, updatedAt: updatedAt)
        return noteFile
    }
    
    func toRecord2() -> CKRecord {
        let record = CKRecord(recordType: RecordEntityType.file.rawValue,recordID: self.recordID)
        return record
    }
    
}
