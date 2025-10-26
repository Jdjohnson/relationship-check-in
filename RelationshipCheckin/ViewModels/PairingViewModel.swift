//
//  PairingViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class PairingViewModel: ObservableObject {
    @Published var isCreatingLink = false
    @Published var isAcceptingLink = false
    @Published var shareURL: URL?
    @Published var error: String?
    @Published var showShareSheet = false
    
    private let cloudKitService = CloudKitService.shared
    private let shareService = ShareService.shared
    
    private var coupleRecord: CKRecord?
    private var share: CKShare?
    private var shareAcceptedObserver: NSObjectProtocol?
    
    // MARK: - Create Invite Link
    
    init() {
        shareAcceptedObserver = NotificationCenter.default.addObserver(
            forName: .rcShareAccepted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { await self.refreshAfterShareAccepted() }
        }
    }
    
    deinit {
        if let observer = shareAcceptedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func createInviteLink() async {
        isCreatingLink = true
        error = nil
        
        do {
            // Fetch or create couple record
            let couple = try await cloudKitService.ensureCouple()
            self.coupleRecord = couple
            
            // Create share
            let share = try await shareService.createShare(for: couple)
            self.share = share
            
            // Get iCloud share URL for system share sheet
            if let url = shareService.getShareURL(for: share) {
                self.shareURL = url
                self.showShareSheet = true
            }
            
            isCreatingLink = false
        } catch {
            if let nsError = error as NSError?,
               nsError.domain == "ShareService",
               nsError.code == -2 {
                self.error = "Only the owner can create invites. Ask your partner to use Accept Invite."
            } else if let ck = error as? CKError {
                self.error = "CloudKit: \(ck.code) – \(ck.localizedDescription)"
            } else {
                self.error = "Failed to create invite link: \(error.localizedDescription)"
            }
            isCreatingLink = false
        }
    }
    
    @MainActor
    func refreshAfterShareAccepted() async {
        do {
            _ = try await cloudKitService.ensureCouple()
            self.error = nil
        } catch {
            self.error = "Paired, but failed to sync: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Deep Link Builder
    
    private func makeAcceptDeepLink(from shareURL: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "rc"
        components.host = "accept"
        components.queryItems = [URLQueryItem(name: "share", value: shareURL.absoluteString)]
        return components.url
    }
    
    // MARK: - Accept Invite Link
    
    func acceptInviteLink(url: URL) async {
        isAcceptingLink = true
        error = nil
        
        do {
            // Support both raw CKShare URLs and rc://accept deep links
            let targetURL: URL
            if url.scheme == "rc",
               let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let shareStr = comps.queryItems?.first(where: { $0.name == "share" })?.value,
               let shareURL = URL(string: shareStr) {
                targetURL = shareURL
            } else {
                targetURL = url
            }
            let metadata = try await shareService.fetchShareMetadata(from: targetURL)
            try await shareService.acceptShare(metadata: metadata)
            
            isAcceptingLink = false
        } catch {
            self.error = "Failed to accept invite: \(error.localizedDescription)"
            isAcceptingLink = false
        }
    }
    
    // MARK: - Complete Pairing
    
    func completePairing() async {
        // After partner accepts, stop sharing to lock at two users
        if let share = share {
            do {
                try await shareService.stopSharing(share: share)
            } catch {
                print("Error stopping share: \(error)")
            }
        }
    }
}
