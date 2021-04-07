//
//  CloudModel.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/3/30.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import CloudKit

class CloudModel {
    
    // MARK: - iCloud Info
    let container: CKContainer
    let publicDB: CKDatabase
    let privateDB: CKDatabase
    
    static var currentModel = CloudModel()
    private(set) var notes: [Note] = []
    
    init() {
      container = CKContainer.default()
      publicDB = container.publicCloudDatabase
      privateDB = container.privateCloudDatabase
    }
    
    @objc func refresh(_ completion: @escaping (Error?) -> Void) {
      // 1.
      let predicate = NSPredicate(value: true)
      // 2.
      let query = CKQuery(recordType: "Note", predicate: predicate)
      establishments(forQuery: query, completion)
    }
    
    
    private func establishments(forQuery query: CKQuery, _ completion: @escaping (Error?) -> Void) {
      publicDB.perform(query, inZoneWith: CKRecordZone.default().zoneID) { [weak self] results, error in
        guard let self = self else { return }
        if let error = error {
          DispatchQueue.main.async {
            completion(error)
          }
          return
        }
        guard let results = results else { return }
        self.notes = results.compactMap {
            self.extractNote(from: $0)
        }
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }
}


extension CloudModel {
    func extractNote(from record: CKRecord) -> Note? {
        guard
          let id = record["id"] as? String,
            let title = record["title"] as? String,
            let content = record["content"] as? String,
            let status = record["status"] as? Int,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
          else { return nil }
        guard let noteStatus = NoteStatus.init(rawValue: status) else { return nil }
        let note = Note(id: id, title: title, content: content, status: noteStatus, createdAt: createdAt, updatedAt: updatedAt)
        return note
    }
}
