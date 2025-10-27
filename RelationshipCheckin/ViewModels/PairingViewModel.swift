//
//  PairingViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import CloudKit
import SwiftUI
import UIKit
import Combine

@MainActor
class PairingViewModel: ObservableObject {
    @Published var isCreatingLink = false
    @Published var isAcceptingLink = false
    @Published var shareURL: URL?
    @Published var error: String?
    @Published var showShareSheet = false
    
    private let cloudKitService = CloudKitService.shared
    private let shareService = ShareService.shared
    
    private var share: CKShare?
    private var shareAcceptedObserver: NSObjectProtocol?
    private var shareFailedObserver: NSObjectProtocol?
    private var scenePhaseCancellable: AnyCancellable?
    private var pairingWatcherTask: Task<Void, Never>?
    
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

        shareFailedObserver = NotificationCenter.default.addObserver(
            forName: .rcShareFailed,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            Task { [weak self] in
                await self?.handleShareFailed(error: notification.object as? Error)
            }
        }

        cloudKitService.restorePersistedState()
        Task { try? await self.cloudKitService.checkPairingStatus() }

        scenePhaseCancellable = NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { try? await self.cloudKitService.checkPairingStatus() }
            }
    }
    
    deinit {
        if let observer = shareAcceptedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = shareFailedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        scenePhaseCancellable?.cancel()
        pairingWatcherTask?.cancel()
    }

    @MainActor
    private func handleShareFailed(error: Error?) {
        isAcceptingLink = false
        if let error {
            self.error = "Failed to accept invite: \(error.localizedDescription)"
        } else {
            self.error = "Failed to accept invite. Please try again."
        }
    }

    func createInviteLink() async {
        isCreatingLink = true
        error = nil
        
        do {
            let result = try await shareService.createShareURLForCouple()
            self.share = result.share
            self.shareURL = result.url
            self.showShareSheet = true
            startPairingWatcher()
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

    private func startPairingWatcher() {
        pairingWatcherTask?.cancel()
        pairingWatcherTask = Task { [weak self] in
            guard let self else { return }
            for _ in 0..<40 {
                if Task.isCancelled { break }
                try? await self.cloudKitService.checkPairingStatus()
                if self.cloudKitService.isPaired { break }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
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
