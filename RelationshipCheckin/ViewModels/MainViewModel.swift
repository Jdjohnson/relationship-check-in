//
//  MainViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class MainViewModel: ObservableObject {
    @Published var partnerTodayEntry: DailyEntry?
    @Published var myTodayEntry: DailyEntry?
    @Published var isLoading = false
    @Published var error: String?
    
    private let supabase = SupabaseService.shared
    
    init() {
        Task {
            await loadTodayEntries()
        }
    }
    
    func loadTodayEntries() async {
        isLoading = true
        error = nil
        
        let today = Calendar.current.startOfDay(for: Date())
        do {
            guard let coupleId = supabase.coupleId, let userId = supabase.currentUser?.id else { return }
            let rows: [DailyEntryDB] = try await supabase.client.database
                .from("daily_entries")
                .select()
                .eq("couple_id", value: coupleId)
                .eq("date", value: today)
                .execute()
                .value
            if let mine = rows.first(where: { $0.authorUserId == userId }) {
                self.myTodayEntry = DailyEntry(
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
                self.partnerTodayEntry = DailyEntry(
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
    
    func refresh() async {
        await loadTodayEntries()
    }
}

