//
//  Mood.swift
//  RelationshipCheckin
//
//  Updated with custom palette - 10/10/2025
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
