//
//  NotesSyncEngine.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/4/3.
//  Copyright © 2021 hanxk. All rights reserved.
//

import Foundation
import CloudKit
import RxSwift


extension Notification.Name {
    public static let noteInserted = Notification.Name(rawValue: "noteInserted")
    public static let noteUpdated = Notification.Name(rawValue: "noteUpdated")
    public static let noteDeleted = Notification.Name(rawValue: "noteDeleted")
}

// icloud 同步
class NotesSyncEngine {
    
    private struct Constants {
        static let previousChangeToken = "PreviousChangeToken"
        static let noteRecordType = "Note"
        static let tagRecordType = "Tag"
        static let zoneName = "mysparkZone"
        static let lastSyncDate = "lastSyncDate"
    }
    
    // MARK: - iCloud Info
    private let container: CKContainer
//    private let publicDB: CKDatabase
    private let privateDB: CKDatabase
    let zone:CKRecordZone
    private var zoneID:CKRecordZone.ID {
        return self.zone.zoneID
    }
//    private let zoneCreateOption:CKModifyRecordZonesOperation
    
    static var shared = NotesSyncEngine()
    private(set) var notes: [Note] = []
    
    private lazy var operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
   }()
    
    private var disposebag = DisposeBag()
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

    private init() {
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        zone = CKRecordZone(zoneName: Constants.zoneName)
    }
    
    func setup() {
        let sync = SyncOperation(action: .setup)
        operationQueue.addOperation(sync)
    }
    
    func pushLocalToRemote() {
        let sync = SyncOperation(action: .push)
        operationQueue.addOperation(sync)
    }
    
    func fetchRemoteChanges() {
        let sync = SyncOperation(action: .fetch)
        operationQueue.addOperation(sync)
    }
}
//MARK database changes
extension NotesSyncEngine {
    
    fileprivate func subscribeToLocalDatabaseChanges() {
        NotificationCenter.default.addObserver(self, selector: #selector(noteInserted(_:)), name: .noteInserted, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noteUpdated(_:)), name: .noteUpdated, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noteDeleted(_:)), name: .noteDeleted, object:nil)
    }
    
    @objc func noteInserted(_ notification: Notification? = nil) {
    }
    @objc func noteUpdated(_ notification: Notification? = nil) {
        
    }
    @objc func noteDeleted(_ notification: Notification? = nil) {
    }
}


extension NotesSyncEngine {
//    private func retryCloudKitOperationIfPossible(with error: Error?, block: @escaping () -> ()) {
//        guard let error = error as? CKError else {
//            slog("CloudKit puked ¯\\_(ツ)_/¯")
//            return
//        }
//
//        guard let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? NSNumber else {
//            slog("CloudKit error: \(error)")
//            return
//        }
//
//        slog("CloudKit operation error, retrying after \(retryAfter) seconds...")
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + retryAfter.doubleValue) {
//            block()
//        }
//    }
    
}
