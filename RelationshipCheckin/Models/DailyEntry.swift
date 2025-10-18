//
//  DailyEntry.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit

struct DailyEntry: Identifiable, Equatable {
    let id: String // CKRecord.ID as string
    let date: Date
    let authorUserRecordID: CKRecord.Reference
    var morningNeed: String?
    var eveningMood: Mood?
    var gratitude: String?
    var tomorrowGreat: String?
    let coupleReference: CKRecord.Reference
    
    var authorName: String {
        authorUserRecordID.recordID.recordName
    }
    
    // Create record name for idempotent upsert
    static func recordName(for date: Date, userRecordName: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        let dateString = formatter.string(from: date)
        return "DailyEntry_\(dateString)_\(userRecordName)"
    }
    
    // Convert to CKRecord
    func toCKRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: "DailyEntry", recordID: recordID)
        
        record["date"] = date as CKRecordValue
        record["authorUserRecordID"] = authorUserRecordID
        record["couple"] = coupleReference
        
        if let morningNeed = morningNeed {
            record["morningNeed"] = morningNeed as CKRecordValue
        }
        if let eveningMood = eveningMood {
            record["eveningMood"] = eveningMood.rawValue as CKRecordValue
        }
        if let gratitude = gratitude {
            record["gratitude"] = gratitude as CKRecordValue
        }
        if let tomorrowGreat = tomorrowGreat {
            record["tomorrowGreat"] = tomorrowGreat as CKRecordValue
        }
        
        return record
    }
    
    // Create from CKRecord
    static func from(record: CKRecord) -> DailyEntry? {
        guard let date = record["date"] as? Date,
              let authorRef = record["authorUserRecordID"] as? CKRecord.Reference,
              let coupleRef = record["couple"] as? CKRecord.Reference else {
            return nil
        }
        
        let morningNeed = record["morningNeed"] as? String
        let eveningMoodInt = record["eveningMood"] as? Int
        let eveningMood = eveningMoodInt != nil ? Mood(rawValue: eveningMoodInt!) : nil
        let gratitude = record["gratitude"] as? String
        let tomorrowGreat = record["tomorrowGreat"] as? String
        
        return DailyEntry(
            id: record.recordID.recordName,
            date: date,
            authorUserRecordID: authorRef,
            morningNeed: morningNeed,
            eveningMood: eveningMood,
            gratitude: gratitude,
            tomorrowGreat: tomorrowGreat,
            coupleReference: coupleRef
        )
    }
}

