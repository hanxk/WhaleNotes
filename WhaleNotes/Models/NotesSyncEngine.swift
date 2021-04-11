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
    public static let remoteNotesChanged = Notification.Name(rawValue: "remoteNotesChanged")
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
    private var changesObserver: NSObjectProtocol?
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


extension NotesSyncEngine {
    
}
