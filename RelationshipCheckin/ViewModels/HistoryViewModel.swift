//
//  HistoryViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var partnerEntry: DailyEntry?
    @Published var myEntry: DailyEntry?
    @Published var isLoading = false
    @Published var error: String?
    
    private let cloudKitService = CloudKitService.shared
    
    func loadEntries(for date: Date) async {
        isLoading = true
        error = nil
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        
        do {
            let entries = try await cloudKitService.fetchEntriesForDate(startOfDay)
            
            // Separate my entry from partner's entry
            if let myUserRecordID = cloudKitService.currentUserRecordID {
                self.myEntry = entries.first { $0.authorUserRecordID.recordID == myUserRecordID }
                self.partnerEntry = entries.first { $0.authorUserRecordID.recordID != myUserRecordID }
            }
            
            isLoading = false
        } catch {
            self.error = "Failed to load entries: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

