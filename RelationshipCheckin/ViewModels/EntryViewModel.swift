//
//  EntryViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI
import Supabase
import UIKit

@MainActor
class EntryViewModel: ObservableObject {
    @Published var morningNeed: String = ""
    @Published var eveningMood: Mood?
    @Published var gratitude: String = ""
    @Published var tomorrowGreat: String = ""
    
    @Published var isSaving = false
    @Published var error: String?
    @Published var showSuccess = false
    
    private let supabase = SupabaseService.shared
    let entryType: EntryType
    
    init(entryType: EntryType) {
        self.entryType = entryType
        Task {
            await loadTodayEntry()
        }
    }
    
    // MARK: - Load Today's Entry
    
    func loadTodayEntry() async {
        guard let userId = supabase.currentUser?.id, let coupleId = supabase.coupleId else { return }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        do {
            let rows: [DailyEntryDB] = try await supabase.client.database
                .from("daily_entries")
                .select()
                .eq("author_user_id", value: userId)
                .eq("couple_id", value: coupleId)
                .eq("date", value: todayString)
                .execute()
                .value
            if let row = rows.first {
                self.morningNeed = row.morningNeed ?? ""
                self.eveningMood = row.eveningMood.flatMap { Mood(rawValue: $0) }
                self.gratitude = row.gratitude ?? ""
                self.tomorrowGreat = row.tomorrowGreat ?? ""
            }
        } catch {
            print("Error loading today's entry: \(error)")
        }
    }
    
    // MARK: - Save Entry
    
    func saveEntry() async {
        guard let userId = supabase.currentUser?.id, let coupleId = supabase.coupleId else {
            self.error = "Not properly initialized"
            return
        }
        
        isSaving = true
        error = nil
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        do {
            struct DailyEntryUpsert: Encodable {
                let couple_id: UUID
                let author_user_id: UUID
                let date: String
                let morning_need: String?
                let evening_mood: Int?
                let gratitude: String?
                let tomorrow_great: String?
            }
            let payload = DailyEntryUpsert(
                couple_id: coupleId,
                author_user_id: userId,
                date: todayString,
                morning_need: morningNeed.isEmpty ? nil : morningNeed,
                evening_mood: eveningMood?.rawValue,
                gratitude: gratitude.isEmpty ? nil : gratitude,
                tomorrow_great: tomorrowGreat.isEmpty ? nil : tomorrowGreat
            )
            _ = try await supabase.client.database
                .from("daily_entries")
                .upsert(payload, onConflict: "author_user_id,date")
                .execute()
            showSuccess = true
            isSaving = false
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
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
