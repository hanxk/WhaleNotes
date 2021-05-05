//
//  SyncOperation.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/4/5.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import CloudKit
enum ZoneError: Error {
  case ZoneCreationFailed
  case ZoneSubscriptionCreationFailed
}
enum SyncAction {
    case setup
    case fetch
    case push
}
private struct Constants {
    static let previousChangeToken = "PreviousChangeToken"
    static let noteRecordType = "Note"
    static let tagRecordType = "Tag"
    static let zoneName = "mysparkZone"
    static let lastPushDate = "lastSyncDate"
}
class SyncOperation: Operation {
    
    var zone:CKRecordZone {
        return NotesSyncEngine.shared.zone
    }
    
    var zoneID:CKRecordZone.ID {
        return zone.zoneID
    }
    private lazy var operationQueue: OperationQueue = {
      let operationQueue = OperationQueue()
      operationQueue.maxConcurrentOperationCount = 1
      return operationQueue
    }()
    private var newChangedToken: CKServerChangeToken? = nil
    
    private var previousChangeToken: CKServerChangeToken? {
        get {
            guard let tokenData = UserDefaults.standard.object(forKey: Constants.previousChangeToken) as? Data else { return nil }
            do {
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
            }catch {
                return nil
            }
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.setNilValueForKey(Constants.previousChangeToken)
                return
            }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
                UserDefaults.standard.set(data, forKey: Constants.previousChangeToken)
            }catch {
                
            }
            
        }
    }
    private var lastPushDate: Date {
        get {
           let date = UserDefaults.standard.date(forKey: Constants.lastPushDate) ?? Date.distantPast
           return date
        }
        set {
            UserDefaults.standard.set(Date(), forKey: Constants.lastPushDate)
        }
    }
    
    private let action:SyncAction
    
    init(action: SyncAction) {
      self.action = action
    }
    
    override func main() {
        do {
            switch action {
            case .setup:
                try setup()
                // 先拉取远程数据，更新前需要与本地数据比对修改时间
                try fetchServerChanges()
                try pushLocalChanges()
                break
            case .fetch:
                try fetchServerChanges()
                break
            case .push:
                try pushLocalChanges()
                break
            }
           logi("COMPLETED SYNC")
        } catch {
          loge("COMPLETED SYNC WITH ERROR ",error)
        }
    }
    
    func setup() throws {
        
        if UserDefaults.standard.date(forKey: Constants.lastPushDate) == nil { // date 初始化
            self.lastPushDate = Date()
        }
        
      var zoneExists = false
      let fetchRecordZonesOperation = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
      fetchRecordZonesOperation.fetchRecordZonesCompletionBlock = { recordZonesByID, error in
        guard let allRecordZonesByID = recordZonesByID, error == nil else {
          return
        }
        zoneExists = allRecordZonesByID[self.zoneID] != nil
      }
      let operationQueue = OperationQueue()
      operationQueue.addOperation(fetchRecordZonesOperation)
      operationQueue.waitUntilAllOperationsAreFinished()
      guard zoneExists == false else {
        return
      }
      try self.createZone()
    }
    
    func perform() throws {
        try pushLocalChanges()
        try fetchServerChanges()
//      do {
//        try applyLocalChanges()
//        if changeManager.hasChanges() == false {
//          try applyServerChanges()
//        }
//        try backingStoreContext.saveIfHasChanges()
//        try storeContext.saveIfHasChanges()
//      } catch SyncError.ConflictsDetected(let conflictedRecordsWithChanges) {
//        do {
//          try resolveConflicts(conflictedRecordsWithChanges: conflictedRecordsWithChanges)
//          try applyLocalChanges()
//          if changeManager.hasChanges() == false {
//            try applyServerChanges()
//          }
//          try backingStoreContext.saveIfHasChanges()
//          try storeContext.saveIfHasChanges()
//        }
//      }
    }
}


//MARK: local changes
extension SyncOperation {
    func pushLocalChanges() throws {
        
        var recordsToUpdate:[CKRecord] = []
        var recordIDsToDelete:[CKRecord.ID] = []
        
        // notes
        let notes = try NotesStore.shared.queryChangedNotes(date: lastPushDate)
        for note in notes {
            if note.isDel {
                recordIDsToDelete.append(note.recordID)
                continue
            }
            recordsToUpdate.append(note.toRecord())
        }
        
        // tags
        let tags = try NotesStore.shared.queryChangedTags(date: lastPushDate)
        for tag in tags {
            if tag.isDel {
                recordIDsToDelete.append(tag.recordID)
                continue
            }
            recordsToUpdate.append(tag.toRecord())
        }
        
        
        if recordIDsToDelete.count + recordsToUpdate.count == 0 { return }
        
        var error:Error? = nil
        pushRecordsToCloudKit(recordsToUpdate: recordsToUpdate, recordIDsToDelete: recordIDsToDelete) { err in
            error = err
        }
        if let err = error  { throw err }
        logi("push local changes")
        // 更新同步日期
        self.lastPushDate = Date()
    }
    
    
    fileprivate func pushRecordsToCloudKit(recordsToUpdate: [CKRecord], recordIDsToDelete: [CKRecord.ID], completion: ((Error?) -> ())? = nil) {
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToUpdate, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.savePolicy =  .allKeys
//        operation.addDependency(zoneCreateOption)
        modifyRecordsOperation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            guard error == nil
                  else {
                logi("Error modifying records: \(error!)")
//                self?.retryCloudKitOperationIfPossible(with: error) {
//                    self?.pushRecordsToCloudKit(recordsToUpdate: recordsToUpdate,
//                                                recordIDsToDelete: recordIDsToDelete,
//                                                completion: completion)
//                }
                completion?(error)
                return
            }
            logi("Finished saving records")
            completion?(nil)
        }
        operationQueue.addOperation(modifyRecordsOperation)
        operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    /// Helper method to retry a CloudKit operation when its error suggests it
    ///
    /// - Parameters:
    ///   - error: The error returned from a CloudKit operation
    ///   - block: A block to be executed after a delay if the error is recoverable
    /// - Returns: If the error can't be retried, returns the error
    func retryCloudKitOperationIfPossible(with error: Error?, block: @escaping () -> ()) -> Error? {
        guard let effectiveError = error as? CKError else {
            // not a CloudKit error or no error present, just return the original error
            return error
        }
        
        guard let retryAfter = effectiveError.retryAfterSeconds else {
        // CloudKit error, can't  be retried, return the error
            return effectiveError
        }

        // CloudKit operation can be retried, schedule `block` to be executed later
        
        DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter) {
            block()
        }
        
        return nil
    }
}


//MARK: server changes
extension SyncOperation {
    func fetchServerChanges() throws {
        let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        options.previousServerChangeToken = previousChangeToken
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [self.zoneID], configurationsByRecordZoneID:[self.zoneID:options])
        
        var updatedRecords = [CKRecord]()
        
        var deletedIdentifiers = [String:[CKRecord.ID]]()
        
        var error:Error? = nil
        
        operation.recordChangedBlock = {
            updatedRecords.append($0)
        }
        operation.recordWithIDWasDeletedBlock = { recordID,recordType in
            deletedIdentifiers[recordType]?.append(recordID)
        }
        operation.fetchRecordZoneChangesCompletionBlock = { err in
            error = err
        }
        operation.recordZoneChangeTokensUpdatedBlock = { [weak self] _, changeToken, _ in
            guard let self = self else { return }
            guard let changeToken = changeToken else { return }
            self.newChangedToken = changeToken
        }
        operation.recordZoneFetchCompletionBlock = {zoneID,changeToken,data,bb,error in
            if error == nil {
                self.newChangedToken = changeToken
            }
        }
        operationQueue.addOperation(operation)
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if let err = error { throw err }
        
        
        // 删除
        for (recordType,recordIDs) in deletedIdentifiers {
            if recordType == Constants.noteRecordType {
                let noteIDs = recordIDs.map{$0.recordName}
                try self.deleteNotesForever(noteIDs: noteIDs)
                continue
            }
            if recordType == Constants.tagRecordType {
                let tagIDs = recordIDs.map{$0.recordName}
                try self.deleteTagsForever(tagIDs: tagIDs)
            }
        }
        
        // 保存更新
        try processFetchedRecords(updatedRecords)
        self.previousChangeToken = newChangedToken
        
        if updatedRecords.isNotEmpty || deletedIdentifiers.count > 0 {
            DispatchQueue.main.async {
                EventManager.shared.post(name: .REMOTE_DATA_CHANGED)
            }
        }
        
    }
    private func deleteNotesForever(noteIDs:[String]) throws {
        logi("deleteNotesForever \(noteIDs)")
        try NotesStore.shared.deleteNotesForever(noteIDs: noteIDs)
    }
    private func deleteTagsForever(tagIDs:[String]) throws {
        logi("deleteTagsForever \(tagIDs)")
        try NotesStore.shared.deleteTagsForever(tagIDs: tagIDs)
    }
}

extension SyncOperation {
    func createZone() throws {
      var error: Error?
      let operationQueue = OperationQueue()
      let modifyRecordZonesOperation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
      modifyRecordZonesOperation.modifyRecordZonesCompletionBlock = { (_,_,operationError) in
        error = operationError
      }
      operationQueue.addOperation(modifyRecordZonesOperation)
      operationQueue.waitUntilAllOperationsAreFinished()
      guard error == nil else {
        throw ZoneError.ZoneCreationFailed
      }
    }
    
    private func processFetchedRecords(_ records:[CKRecord]) throws {
        var notes:[Note] = []
        var tags:[Tag] = []
        records.forEach {
            let recordType = $0.recordType
            switch recordType {
            case Constants.noteRecordType:
                if let note = Note.from(from: $0) {
//                    let note = noteAndTags.0
//                    let noteTags = noteAndTags.1.map{NoteTag(noteId: note.id, tagId: $0)}
                    notes.append(note)
//                    tags.append(noteTags)
                }
                break
            case Constants.tagRecordType:
                if let tag = Tag.from(from: $0) {
                    tags.append(tag)
                }
                break
            default:
                break
            }
        }
        if notes.count == 0 && tags.count == 0 {
            return
        }
        logi("更新来自 iCloud 中的数据")
        try NotesStore.shared.save(notes: notes, tags: tags)
    }
    
//    private func processFetchedRecords(_ records:[CKRecord.ID : CKRecord]) throws {
//        var notes:[Note] = []
//        var tags:[Tag] = []
//        records.values.forEach {
//            let recordType = $0.recordType
//            switch recordType {
//            case Constants.noteRecordType:
//                if let note = Note.from(from: $0) {
//                    notes.append(note)
//                }
//                break
//            case Constants.tagRecordType:
//                if let tag = Tag.from(from: $0) {
//                    tags.append(tag)
//                }
//                break
//            default:
//                break
//            }
//        }
//        if notes.count == 0 && tags.count == 0 {
//            return
//        }
//        logi("更新来自 iCloud 中的数据")
//        try NotesStore.shared.save(notes: notes, tags: tags)
//    }
}
