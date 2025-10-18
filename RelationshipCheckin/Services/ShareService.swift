//
//  ShareService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class ShareService: ObservableObject {
    static let shared = ShareService()
    
    @Published var isSharing = false
    @Published var shareURL: URL?
    @Published var error: Error?
    
    private let cloudKitService = CloudKitService.shared
    
    private init() {}
    
    // MARK: - Create Share
    
    func createShare(for coupleRecord: CKRecord) async throws -> CKShare {
        let share = CKShare(rootRecord: coupleRecord)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "Relationship Check-in" as CKRecordValue
        
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        let privateDB = container.privateCloudDatabase
        
        // Save both the record and share
        let (savedRecords, _) = try await privateDB.modifyRecords(saving: [coupleRecord, share], deleting: [])
        
        // Find the saved share in the results
        for (_, result) in savedRecords {
            if let record = try? result.get(), let savedShare = record as? CKShare {
                return savedShare
            }
        }
        
        throw NSError(domain: "ShareService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create share"])
    }
    
    func getShareURL(for share: CKShare) -> URL? {
        return share.url
    }
    
    // MARK: - Accept Share
    
    func acceptShare(metadata: CKShare.Metadata) async throws {
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        
        do {
            _ = try await container.accept(metadata)

            let userRecordID = try await container.userRecordID()
            cloudKitService.currentUserRecordID = userRecordID

            await cloudKitService.checkPairingStatus()
            try await cloudKitService.updateCoupleWithPartner(partnerRecordID: userRecordID)
            self.error = nil
        } catch {
#if DEBUG
            do {
                let userRecordID = try await container.userRecordID()
                cloudKitService.currentUserRecordID = userRecordID

                await cloudKitService.checkPairingStatus()
                try await cloudKitService.updateCoupleWithPartner(partnerRecordID: userRecordID)
                self.error = nil
                return
            } catch let fallbackError {
                self.error = fallbackError
                throw fallbackError
            }
#else
            self.error = error
            throw error
#endif
        }
    }
    
    // MARK: - Stop Sharing (Lock to two users)
    
    func stopSharing(share: CKShare) async throws {
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        let privateDB = container.privateCloudDatabase
        
        // Delete the share to prevent more people from joining
        try await privateDB.deleteRecord(withID: share.recordID)
    }
    
    // MARK: - Fetch Share Metadata
    
    func fetchShareMetadata(from url: URL) async throws -> CKShare.Metadata {
        let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        return try await container.shareMetadata(for: url)
    }
}
