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
    private let container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
    
    private init() {}
    
    // MARK: - Create Share

    func createShareURLForCouple() async throws -> (share: CKShare, url: URL) {
        let coupleRecord = try await cloudKitService.ensureCouple()
        let share = try await createShare(for: coupleRecord)
        guard let url = share.url else {
            throw NSError(
                domain: "ShareService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Share URL unavailable"]
            )
        }
        return (share, url)
    }

    private func fetchExistingShare(for rootID: CKRecord.ID, in db: CKDatabase) async throws -> CKShare? {
        let predicate = NSPredicate(format: "rootRecord == %@", rootID)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)

        do {
            let (results, _) = try await db.records(matching: query, inZoneWith: rootID.zoneID)
            for (_, result) in results {
                if case .success(let record as CKShare) = result {
                    return record
                }
            }
            return nil
        } catch let ck as CKError where
            ck.code == .unknownItem ||
            ck.code == .zoneNotFound ||
            ck.code == .invalidArguments {
            return nil
        }
    }
    
    func createShare(for coupleRecord: CKRecord) async throws -> CKShare {
        let db = container.privateCloudDatabase
        
        let root: CKRecord
        do {
            root = try await db.record(for: coupleRecord.recordID)
        } catch let ck as CKError where ck.code == .unknownItem || ck.code == .permissionFailure {
            throw NSError(
                domain: "ShareService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "This Couple belongs to your partner. Only the owner can create invites."]
            )
        }
        
        func attemptCreate(with record: CKRecord) async throws -> CKShare {
            let share = CKShare(rootRecord: record)
            share.publicPermission = .readWrite
            share[CKShare.SystemFieldKey.title] = "Relationship Check-in" as CKRecordValue
            
            let (saved, _) = try await db.modifyRecords(saving: [record, share], deleting: [])
            if let result = saved[share.recordID] {
                switch result {
                case .success(let record as CKShare):
                    return record
                case .success:
                    throw NSError(
                        domain: "ShareService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unexpected share save result"]
                    )
                case .failure(let error):
                    throw error
                }
            }
            throw NSError(
                domain: "ShareService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Share missing from modifyRecords results"]
            )
        }
        
        do {
            return try await attemptCreate(with: root)
        } catch let ck as CKError {
            if ck.code == .serverRecordChanged {
                if let existing = try await fetchExistingShare(for: root.recordID, in: db) {
                    return existing
                }
            }
            throw ck
        }
    }

    func getShareURL(for share: CKShare) -> URL? {
        return share.url
    }

    // MARK: - Accept Share

    func acceptShare(metadata: CKShare.Metadata) async throws {
        do {
            _ = try await container.accept(metadata)

            let userRecordID = try await container.userRecordID()
            cloudKitService.currentUserRecordID = userRecordID

            if cloudKitService.coupleRecordID == nil,
               let rootRecordID = extractRootRecordID(from: metadata) {
                cloudKitService.coupleRecordID = rootRecordID
            }

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
        let privateDB = container.privateCloudDatabase
        
        // Delete the share to prevent more people from joining
        try await privateDB.deleteRecord(withID: share.recordID)
    }

    // MARK: - Fetch Share Metadata

    func metadata(for url: URL) async throws -> CKShare.Metadata {
        return try await container.shareMetadata(for: url)
    }
    
    func fetchShareMetadata(from url: URL) async throws -> CKShare.Metadata {
        return try await metadata(for: url)
    }

    private func extractRootRecordID(from metadata: CKShare.Metadata) -> CKRecord.ID? {
        if #available(iOS 16.0, *), let root = metadata.rootRecord {
            return root.recordID
        }

        let selector = NSSelectorFromString("rootRecordID")
        guard metadata.responds(to: selector),
              let unmanaged = metadata.perform(selector),
              let recordID = unmanaged.takeUnretainedValue() as? CKRecord.ID else {
            return nil
        }
        return recordID
    }
}
