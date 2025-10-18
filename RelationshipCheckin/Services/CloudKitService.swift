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
    
    @Published var isInitializing = true
    @Published var isPaired = false
    @Published var currentUserRecordID: CKRecord.ID?
    @Published var coupleRecordID: CKRecord.ID?
    @Published var partnerUserRecordID: CKRecord.ID?
    @Published var error: Error?
    
    private let customZoneName = "RelationshipZone"
    var customZoneID: CKRecordZone.ID?
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.jaradjohnson.RelationshipCheckin")
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        do {
            // Fetch current user
            let userRecordID = try await container.userRecordID()
            self.currentUserRecordID = userRecordID
            
            // Create or fetch custom zone
            let zoneID = CKRecordZone.ID(zoneName: customZoneName, ownerName: CKCurrentUserDefaultName)
            self.customZoneID = zoneID
            
            do {
                _ = try await privateDatabase.recordZone(for: zoneID)
            } catch {
                // Zone doesn't exist, create it
                let zone = CKRecordZone(zoneID: zoneID)
                _ = try await privateDatabase.save(zone)
            }
            
            // Check if already paired
            await checkPairingStatus()
            
            self.isInitializing = false
        } catch {
            self.error = error
            self.isInitializing = false
            print("CloudKit initialization error: \(error)")
        }
    }
    
    // MARK: - Pairing
    
    func checkPairingStatus() async {
        do {
            // Try to find Couple record in private DB
            let query = CKQuery(recordType: "Couple", predicate: NSPredicate(value: true))
            let (matchResults, _) = try await privateDatabase.records(matching: query, inZoneWith: customZoneID)
            
            if let firstMatch = matchResults.first {
                let coupleRecord = try firstMatch.1.get()
                self.coupleRecordID = coupleRecord.recordID
                
                if let partnerRef = coupleRecord["partnerUserRecordID"] as? CKRecord.Reference {
                    self.partnerUserRecordID = partnerRef.recordID
                    self.isPaired = true
                } else {
                    self.isPaired = false
                }
                return
            }
            
            // Try shared database
            let sharedQuery = CKQuery(recordType: "Couple", predicate: NSPredicate(value: true))
            let (sharedResults, _) = try await sharedDatabase.records(matching: sharedQuery)
            
            if let firstShared = sharedResults.first {
                let coupleRecord = try firstShared.1.get()
                self.coupleRecordID = coupleRecord.recordID
                
                if let partnerRef = coupleRecord["partnerUserRecordID"] as? CKRecord.Reference {
                    self.partnerUserRecordID = partnerRef.recordID
                    self.isPaired = true
                } else {
                    self.isPaired = false
                }
            } else {
                self.isPaired = false
            }
        } catch {
            print("Error checking pairing status: \(error)")
            self.isPaired = false
        }
    }
    
    func createCouple() async throws -> CKRecord {
        guard let zoneID = customZoneID, let userRecordID = currentUserRecordID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not initialized"])
        }

        let recordID = CKRecord.ID(recordName: "Couple_\(UUID().uuidString)", zoneID: zoneID)
        let coupleRecord = CKRecord(recordType: "Couple", recordID: recordID)

        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        coupleRecord["ownerUserRecordID"] = userReference

        let savedRecord = try await privateDatabase.save(coupleRecord)
        self.coupleRecordID = savedRecord.recordID

        return savedRecord
    }

    func ensureCouple() async throws -> CKRecord {
        if let coupleRecordID = coupleRecordID {
            for database in [sharedDatabase, privateDatabase] {
                if let record = try? await database.record(for: coupleRecordID) {
                    self.coupleRecordID = record.recordID
                    return record
                }
            }
        }

        await checkPairingStatus()

        if let coupleRecordID = coupleRecordID {
            for database in [sharedDatabase, privateDatabase] {
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
        
        // Fetch from appropriate database
        let databases = [sharedDatabase, privateDatabase]
        var coupleRecord: CKRecord?
        
        for db in databases {
            do {
                coupleRecord = try await db.record(for: coupleRecordID)
                if coupleRecord != nil {
                    let partnerReference = CKRecord.Reference(recordID: partnerRecordID, action: .none)
                    coupleRecord!["partnerUserRecordID"] = partnerReference
                    _ = try await db.save(coupleRecord!)
                    
                    self.partnerUserRecordID = partnerRecordID
                    self.isPaired = true
                    return
                }
            } catch {
                continue
            }
        }
        
        throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find couple record"])
    }
    
    // MARK: - Daily Entries
    
    func upsertDailyEntry(_ entry: DailyEntry) async throws {
        guard let zoneID = customZoneID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Zone not initialized"])
        }
        
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
        
        guard let zoneID = customZoneID else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Zone not initialized"])
        }
        
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
            let (results, _) = try await privateDatabase.records(matching: query, inZoneWith: customZoneID)
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
