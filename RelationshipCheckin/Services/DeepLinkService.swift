//
//  DeepLinkService.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI
import CloudKit

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
        
        // Handle accept flow: rc://accept?share=<encoded CKShare URL>
        if url.host == "accept",
           let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let shareStr = comps.queryItems?.first(where: { $0.name == "share" })?.value,
           let shareURL = URL(string: shareStr) {
            Task { @MainActor in
                do {
                    let metadata = try await ShareService.shared.fetchShareMetadata(from: shareURL)
                    try await ShareService.shared.acceptShare(metadata: metadata)
                } catch {
                    print("Accept via deeplink failed: \(error)")
                }
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
