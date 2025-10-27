//
//  CloudKitService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    private let zoneID: CKRecordZone.ID

    @Published var isInitializing = true
    @Published var isPaired = false
    @Published var currentUserRecordID: CKRecord.ID?
    @Published var coupleRecordID: CKRecord.ID?
    @Published var partnerUserRecordID: CKRecord.ID?
    @Published var error: Error?
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
        self.zoneID = CKRecordZone.ID(zoneName: "RelationshipZone", ownerName: CKCurrentUserDefaultName)
    }
    
    // MARK: - Initialization

    func initialize() async {
        do {
            // Fetch current user
            let userRecordID = try await container.userRecordID()
            self.currentUserRecordID = userRecordID
            
            try await ensurePrivateZone()
            
            // Check if already paired
            await checkPairingStatus()
            
            self.isInitializing = false
        } catch {
            self.error = error
            self.isInitializing = false
            print("CloudKit initialization error: \(error)")
        }
    }
    
    // MARK: - Zones
    
    func ensurePrivateZone() async throws {
        do {
            _ = try await privateDatabase.recordZone(for: zoneID)
        } catch let ck as CKError {
            if ck.code == .unknownItem {
                let zone = CKRecordZone(zoneID: zoneID)
                _ = try await privateDatabase.save(zone)
            } else {
                throw ck
            }
        }
    }

    private func findCoupleRecord(for userRecordID: CKRecord.ID) async throws -> CKRecord? {
        let predicate = NSPredicate(format: "ownerUserRecordID == %@ OR partnerUserRecordID == %@", userRecordID, userRecordID)
        let query = CKQuery(recordType: "Couple", predicate: predicate)

        let (privateMatches, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID)
        for (_, result) in privateMatches {
            if let record = try? result.get() {
                return record
            }
        }

        let (sharedMatches, _) = try await sharedDatabase.records(matching: query)
        for (_, result) in sharedMatches {
            if let record = try? result.get() {
                return record
            }
        }

        return nil
    }
    
    private func applyCoupleState(from record: CKRecord) {
        self.coupleRecordID = record.recordID
        if let partnerRef = record["partnerUserRecordID"] as? CKRecord.Reference {
            self.partnerUserRecordID = partnerRef.recordID
            self.isPaired = true
        } else {
            self.partnerUserRecordID = nil
            self.isPaired = false
        }
    }
    
    private func currentUserRecord() async throws -> CKRecord.ID {
        if let id = currentUserRecordID {
            return id
        }
        let id = try await container.userRecordID()
        currentUserRecordID = id
        return id
    }
    
    // MARK: - Pairing
    
    func checkPairingStatus() async {
        do {
            try await ensurePrivateZone()
            let userRecordID = try await currentUserRecord()
            if let coupleID = coupleRecordID {
                for database in [privateDatabase, sharedDatabase] {
                    if let record = try? await database.record(for: coupleID) {
                        applyCoupleState(from: record)
                        return
                    }
                }
            }

            if let record = try await findCoupleRecord(for: userRecordID) {
                applyCoupleState(from: record)
            } else {
                self.partnerUserRecordID = nil
                self.isPaired = false
            }
        } catch {
            print("Error checking pairing status: \(error)")
            self.partnerUserRecordID = nil
            self.isPaired = false
        }
    }
    
    func createCouple() async throws -> CKRecord {
        let userRecordID = try await currentUserRecord()

        let recordID = CKRecord.ID(recordName: "Couple_\(UUID().uuidString)", zoneID: zoneID)
        let coupleRecord = CKRecord(recordType: "Couple", recordID: recordID)
        coupleRecord["ownerUserRecordID"] = CKRecord.Reference(recordID: userRecordID, action: .none)

        let savedRecord = try await privateDatabase.save(coupleRecord)
        applyCoupleState(from: savedRecord)
        return savedRecord
    }

    func ensureCouple() async throws -> CKRecord {
        try await ensurePrivateZone()
        if let coupleRecordID = coupleRecordID {
            // Prefer the owner's private DB record to create/modify shares.
            for database in [privateDatabase, sharedDatabase] {
                if let record = try? await database.record(for: coupleRecordID) {
                    self.coupleRecordID = record.recordID
                    return record
                }
            }
        }

        await checkPairingStatus()

        if let coupleRecordID = coupleRecordID {
            for database in [privateDatabase, sharedDatabase] {
                if let record = try? await database.record(for: coupleRecordID) {
                    self.coupleRecordID = record.recordID
                    return record
                }
            }
        }

        return try await createCouple()
    }
    
    func updateCoupleWithPartner(partnerRecordID: CKRecord.ID) async throws {
        guard let coupleRecordID = coupleRecordID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No couple record"])
        }
        
        let partnerReference = CKRecord.Reference(recordID: partnerRecordID, action: .none)
        for db in [privateDatabase, sharedDatabase] {
            do {
                let record = try await db.record(for: coupleRecordID)
                record["partnerUserRecordID"] = partnerReference
                let saved = try await db.save(record)
                applyCoupleState(from: saved)
                return
            } catch {
                continue
            }
        }

        throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find couple record"])
    }
    
    // MARK: - Daily Entries
    
    func upsertDailyEntry(_ entry: DailyEntry) async throws {
        try await ensurePrivateZone()
        
        let record = entry.toCKRecord(in: zoneID)
        
        // Try shared database first, then private
        do {
            _ = try await sharedDatabase.save(record)
        } catch {
            _ = try await privateDatabase.save(record)
        }
    }
    
    func fetchDailyEntry(for date: Date, userRecordID: CKRecord.ID) async throws -> DailyEntry? {
        let recordName = DailyEntry.recordName(for: date, userRecordName: userRecordID.recordName)
        try await ensurePrivateZone()
        
        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        
        // Try shared database first
        do {
            let record = try await sharedDatabase.record(for: recordID)
            return DailyEntry.from(record: record)
        } catch {
            // Try private database
            do {
                let record = try await privateDatabase.record(for: recordID)
                return DailyEntry.from(record: record)
            } catch {
                return nil
            }
        }
    }
    
    func fetchEntriesForDate(_ date: Date) async throws -> [DailyEntry] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        let query = CKQuery(recordType: "DailyEntry", predicate: predicate)
        
        var entries: [DailyEntry] = []
        
        // Query shared database
        do {
            let (results, _) = try await sharedDatabase.records(matching: query)
            for result in results {
                if let record = try? result.1.get(), let entry = DailyEntry.from(record: record) {
                    entries.append(entry)
                }
            }
        } catch {
            print("Error querying shared database: \(error)")
        }
        
        // Query private database
        do {
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: zoneID)
            for result in results {
                if let record = try? result.1.get(), let entry = DailyEntry.from(record: record) {
                    entries.append(entry)
                }
            }
        } catch {
            print("Error querying private database: \(error)")
        }
        
        return entries
    }
    
    // Helper to get database for operations
    func getActiveDatabase() -> CKDatabase {
        return isPaired ? sharedDatabase : privateDatabase
    }
}
