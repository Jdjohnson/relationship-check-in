//
//  MainViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var partnerTodayEntry: DailyEntry?
    @Published var myTodayEntry: DailyEntry?
    @Published var isLoading = false
    @Published var error: String?
    
    private let cloudKitService = CloudKitService.shared
    
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
            let entries = try await cloudKitService.fetchEntriesForDate(today)
            
            // Separate my entry from partner's entry
            if let myUserRecordID = cloudKitService.currentUserRecordID {
                self.myTodayEntry = entries.first { $0.authorUserRecordID.recordID == myUserRecordID }
                self.partnerTodayEntry = entries.first { $0.authorUserRecordID.recordID != myUserRecordID }
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

