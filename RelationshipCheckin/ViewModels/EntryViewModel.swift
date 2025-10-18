//
//  EntryViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class EntryViewModel: ObservableObject {
    @Published var morningNeed: String = ""
    @Published var eveningMood: Mood?
    @Published var gratitude: String = ""
    @Published var tomorrowGreat: String = ""
    
    @Published var isSaving = false
    @Published var error: String?
    @Published var showSuccess = false
    
    private let cloudKitService = CloudKitService.shared
    let entryType: EntryType
    
    init(entryType: EntryType) {
        self.entryType = entryType
        Task {
            await loadTodayEntry()
        }
    }
    
    // MARK: - Load Today's Entry
    
    func loadTodayEntry() async {
        guard let userRecordID = cloudKitService.currentUserRecordID else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        do {
            if let entry = try await cloudKitService.fetchDailyEntry(for: today, userRecordID: userRecordID) {
                self.morningNeed = entry.morningNeed ?? ""
                self.eveningMood = entry.eveningMood
                self.gratitude = entry.gratitude ?? ""
                self.tomorrowGreat = entry.tomorrowGreat ?? ""
            }
        } catch {
            print("Error loading today's entry: \(error)")
        }
    }
    
    // MARK: - Save Entry
    
    func saveEntry() async {
        guard let userRecordID = cloudKitService.currentUserRecordID,
              let coupleRecordID = cloudKitService.coupleRecordID,
              cloudKitService.customZoneID != nil else {
            error = "Not properly initialized"
            return
        }
        
        isSaving = true
        error = nil
        
        let today = Calendar.current.startOfDay(for: Date())
        let recordName = DailyEntry.recordName(for: today, userRecordName: userRecordID.recordName)
        
        let userReference = CKRecord.Reference(recordID: userRecordID, action: .none)
        let coupleReference = CKRecord.Reference(recordID: coupleRecordID, action: .none)
        
        var entry = DailyEntry(
            id: recordName,
            date: today,
            authorUserRecordID: userReference,
            morningNeed: morningNeed.isEmpty ? nil : morningNeed,
            eveningMood: eveningMood,
            gratitude: gratitude.isEmpty ? nil : gratitude,
            tomorrowGreat: tomorrowGreat.isEmpty ? nil : tomorrowGreat,
            coupleReference: coupleReference
        )
        
        // Load existing entry to merge fields
        if let existingEntry = try? await cloudKitService.fetchDailyEntry(for: today, userRecordID: userRecordID) {
            // Merge: keep existing values if current ones are empty
            if entryType == .evening {
                entry.morningNeed = existingEntry.morningNeed ?? entry.morningNeed
            } else {
                entry.eveningMood = existingEntry.eveningMood ?? entry.eveningMood
                entry.gratitude = existingEntry.gratitude ?? entry.gratitude
                entry.tomorrowGreat = existingEntry.tomorrowGreat ?? entry.tomorrowGreat
            }
        }
        
        do {
            try await cloudKitService.upsertDailyEntry(entry)
            showSuccess = true
            isSaving = false
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            // Auto-dismiss after a moment
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showSuccess = false
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
            isSaving = false
        }
    }
    
    var canSave: Bool {
        switch entryType {
        case .morning:
            return !morningNeed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .evening:
            return eveningMood != nil &&
                   !gratitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !tomorrowGreat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}

