//
//  DailyEntry.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation

struct DailyEntry: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let authorUserId: UUID
    var morningNeed: String?
    var eveningMood: Mood?
    var gratitude: String?
    var tomorrowGreat: String?
    let coupleId: UUID
}

