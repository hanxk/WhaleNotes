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
    static let lastSyncDate = "lastSyncDate"
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
    
    /// Holds the latest change token we got from CloudKit, storing it in UserDefaults
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
    
    private let action:SyncAction
    
    init(action: SyncAction) {
      self.action = action
    }
    
    override func main() {
        do {
            switch action {
            case .setup:
                try setup()
                try applyLocalChanges()
                try applyServerChanges()
                break
            case .fetch:
                try applyServerChanges()
                break
            case .push:
                try applyLocalChanges()
                break
            }
//          print("COMPLETED SYNC ", storeContextSaveNotification!)
//          onCompletion?(storeContextSaveNotification, nil)
           logi("COMPLETED SYNC")
        } catch {
          loge("COMPLETED SYNC WITH ERROR ",error)
//          onCompletion?(nil, error)
        }
    }
    
    func setup() throws {
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
        try applyLocalChanges()
        try applyServerChanges()
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
    func applyLocalChanges() throws {
        // 查询本地已被编辑的 note，然后上传
        let notes = try NotesStore.shared.queryChanged()
        if notes.isEmpty { return }
        
        var recordsToUpdate:[CKRecord] = []
        var recordIDsToDelete:[CKRecord.ID] = []
        
        for note in notes {
            if note.changedType == .delete {
                recordIDsToDelete.append(note.recordID)
            }else{
                let record = note.tooRecord()
                recordsToUpdate.append(record)
            }
        }
        var error:Error? = nil
        pushRecordsToCloudKit(recordsToUpdate: recordsToUpdate, recordIDsToDelete: recordIDsToDelete) { err in
            error = err
        }
        if let err = error  { throw err }
        logi("push local changes")
        // 重置 changed
        try NotesStore.shared.clearChanged()
    }
    
    
    fileprivate func pushRecordsToCloudKit(recordsToUpdate: [CKRecord], recordIDsToDelete: [CKRecord.ID], completion: ((Error?) -> ())? = nil) {
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToUpdate, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.savePolicy =  .changedKeys
//        operation.addDependency(zoneCreateOption)
        modifyRecordsOperation.modifyRecordsCompletionBlock = { [weak self] _, _, error in
            guard error == nil else {
                logi("Error modifying records: \(error!)")
//                self.retryCloudKitOperationIfPossible(with: error) {
//                    self.pushRecordsToCloudKit(recordsToUpdate: recordsToUpdate,
//                                                recordIDsToDelete: recordIDsToDelete,
//                                                completion: completion)
//                }
                return
            }
            logi("Finished saving records")
            completion?(nil)
//            DispatchQueue.main.async {
//
//            }
        }
        operationQueue.addOperation(modifyRecordsOperation)
        operationQueue.waitUntilAllOperationsAreFinished()
    }
}


//MARK: server changes
extension SyncOperation {
    func applyServerChanges() throws {
        let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        options.previousServerChangeToken = previousChangeToken
        
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [self.zoneID], configurationsByRecordZoneID:[self.zoneID:options])
        
        var updatedIdentifiers = [CKRecord.ID]()
        var deletedIdentifiers = [CKRecord.ID]()
        
        var error:Error? = nil
        
        operation.recordChangedBlock = {
            updatedIdentifiers.append($0.recordID)
        }
        operation.recordWithIDWasDeletedBlock = { recordID,recordType in
            deletedIdentifiers.append(recordID)
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
        
        // 更新本地 notes
        try self.consolidateUpdatedCloudNotes(with: updatedIdentifiers)
        if deletedIdentifiers.isNotEmpty {
            try self.deleteNotesForever(noteIDs: deletedIdentifiers.map{$0.recordName})
        }
        self.previousChangeToken = newChangedToken
    }
    
    /// Download a list of records from CloudKit and update the local database accordingly
    private func consolidateUpdatedCloudNotes(with identifiers: [CKRecord.ID]) throws {
        
        var error:Error? = nil
        var records:[CKRecord.ID : CKRecord] = [:]
        
        let operation = CKFetchRecordsOperation(recordIDs: identifiers)
        operation.fetchRecordsCompletionBlock = { r, err in
            error = err
            if let r = r {
               records = r
            }
        }
        operationQueue.addOperation(operation)
        operationQueue.waitUntilAllOperationsAreFinished()
        if let error = error {
            throw error
        }
        try processFetchedRecords(records)
    }
    private func deleteNotesForever(noteIDs:[String]) throws {
        logi("deleteNotesForever \(noteIDs)")
        try NotesStore.shared.deleteNotesForever(noteIDs: noteIDs)
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
    
    private func processFetchedRecords(_ records:[CKRecord.ID : CKRecord]) throws {
        var notes:[Note] = []
        var tags:[Tag] = []
        records.values.forEach {
            let recordType = $0.recordType
            switch recordType {
            case Constants.noteRecordType:
                if let note = Note.from(from: $0) {
                    notes.append(note)
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
}
