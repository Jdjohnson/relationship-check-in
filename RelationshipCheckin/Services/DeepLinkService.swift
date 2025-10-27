//
//  DeepLinkService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI

enum EntryType: String {
    case morning
    case evening
}

struct DeepLinkRoute: Identifiable {
    let id = UUID()
    let entryType: EntryType
}

@MainActor
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()
    
    @Published var activeRoute: DeepLinkRoute?
    
    private init() {}
    
    func handle(url: URL) {
        guard url.scheme == "rc" else { return }
        
        // Handle invite accept: rc://invite/<code>
        if url.host == "invite" {
            Task { @MainActor in
                // Forward to global handler on the currently presented PairingView if needed
                NotificationCenter.default.post(name: Notification.Name("rc.handleInvite"), object: url)
            }
            return
        }
        
        // Handle entry routes: rc://entry/morning or rc://entry/evening
        guard url.host == "entry" else { return }
        let path = url.pathComponents.dropFirst().first ?? ""
        switch path {
        case "morning":
            activeRoute = DeepLinkRoute(entryType: .morning)
        case "evening":
            activeRoute = DeepLinkRoute(entryType: .evening)
        default:
            break
        }
    }
    
    func clearRoute() {
        activeRoute = nil
    }
}
