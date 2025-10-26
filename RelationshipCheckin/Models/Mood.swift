//
//  Mood.swift
//  RelationshipCheckin
//
//  Updated with adaptive dark mode colors - 10/26/2025
//

import Foundation
import SwiftUI

enum Mood: Int, CaseIterable, Codable {
    case great = 0
    case okay = 1
    case difficult = 2
    
    var color: Color {
        switch self {
        case .great: return DesignSystem.Colors.moodGreat // Purple
        case .okay: return DesignSystem.Colors.moodOkay // Gold
        case .difficult: return DesignSystem.Colors.moodDifficult // Navy
        }
    }
    
    // Adaptive color for dark mode support
    func adaptiveColor(for scheme: ColorScheme) -> Color {
        switch self {
        case .great: 
            return scheme == .dark ? DesignSystem.Colors.moodGreatDark : DesignSystem.Colors.moodGreat
        case .okay: 
            return scheme == .dark ? DesignSystem.Colors.moodOkayDark : DesignSystem.Colors.moodOkay
        case .difficult: 
            return scheme == .dark ? DesignSystem.Colors.moodDifficultDark : DesignSystem.Colors.moodDifficult
        }
    }
    
    var displayName: String {
        switch self {
        case .great: return "Great"
        case .okay: return "Okay"
        case .difficult: return "Hard"
        }
    }
    
    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .okay: return "face.dashed.fill"
        case .difficult: return "face.dashed.fill"
        }
    }
}
