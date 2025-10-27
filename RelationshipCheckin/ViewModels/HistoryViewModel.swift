//
//  HistoryViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var partnerEntry: DailyEntry?
    @Published var myEntry: DailyEntry?
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseService.shared
    
    func loadEntries(for date: Date) async {
        isLoading = true
        error = nil
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        do {
            guard let coupleId = supabase.coupleId, let userId = supabase.currentUser?.id else { return }
            let rows: [DailyEntryDB] = try await supabase.client.database
                .from("daily_entries")
                .select()
                .eq("couple_id", value: coupleId)
                .eq("date", value: startOfDay)
                .execute()
                .value
            if let mine = rows.first(where: { $0.authorUserId == userId }) {
                self.myEntry = DailyEntry(
                    id: mine.id,
                    date: mine.date,
                    authorUserId: mine.authorUserId,
                    morningNeed: mine.morningNeed,
                    eveningMood: mine.eveningMood.flatMap { Mood(rawValue: $0) },
                    gratitude: mine.gratitude,
                    tomorrowGreat: mine.tomorrowGreat,
                    coupleId: mine.coupleId
                )
            }
            if let partnerRow = rows.first(where: { $0.authorUserId != userId }) {
                self.partnerEntry = DailyEntry(
                    id: partnerRow.id,
                    date: partnerRow.date,
                    authorUserId: partnerRow.authorUserId,
                    morningNeed: partnerRow.morningNeed,
                    eveningMood: partnerRow.eveningMood.flatMap { Mood(rawValue: $0) },
                    gratitude: partnerRow.gratitude,
                    tomorrowGreat: partnerRow.tomorrowGreat,
                    coupleId: partnerRow.coupleId
                )
            }
            isLoading = false
        } catch {
            self.error = "Failed to load entries: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

