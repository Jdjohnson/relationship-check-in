//
//  PairingViewModel.swift
//  RelationshipCheckin
//
//  Created on 10/10/2025.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import Supabase

@MainActor
class PairingViewModel: ObservableObject {
    @Published var isCreatingLink = false
    @Published var isAcceptingLink = false
    @Published var shareURL: URL?
    @Published var error: String?
    @Published var showShareSheet = false
    
    private let supabase = SupabaseService.shared
    
    private var shareAcceptedObserver: NSObjectProtocol?
    private var shareFailedObserver: NSObjectProtocol?
    private var scenePhaseCancellable: AnyCancellable?
    private var pairingWatcherTask: Task<Void, Never>?
    
    // MARK: - Create Invite Link
    
    init() {
        NotificationCenter.default.addObserver(forName: Notification.Name("rc.handleInvite"), object: nil, queue: .main) { [weak self] note in
            guard let url = note.object as? URL else { return }
            Task { await self?.acceptInviteLink(url: url) }
        }
        Task { await self.supabase.checkPairingStatus() }

        scenePhaseCancellable = NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.supabase.checkPairingStatus() }
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
            guard let userId = supabase.currentUser?.id else { throw NSError(domain: "Pairing", code: -1) }
            let rows: [Couple] = try await supabase.client.database
                .from("couples")
                .insert(["owner_user_id": userId.uuidString])
                .select()
                .execute()
                .value
            guard let couple = rows.first, let code = couple.inviteCode else { throw NSError(domain: "Pairing", code: -2) }
            var components = URLComponents()
            components.scheme = "rc"
            components.host = "invite"
            components.path = "/\(code.uuidString)"
            self.shareURL = components.url
            self.showShareSheet = true
            startPairingWatcher()
            isCreatingLink = false
        } catch {
            self.error = "Failed to create invite link: \(error.localizedDescription)"
            isCreatingLink = false
        }
    }

    private func startPairingWatcher() {
        pairingWatcherTask?.cancel()
        pairingWatcherTask = Task { [weak self] in
            guard let self else { return }
            for _ in 0..<40 {
                if Task.isCancelled { break }
                await self.supabase.checkPairingStatus()
                if self.supabase.isPaired { break }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
    
    @MainActor
    func refreshAfterShareAccepted() async { }
    
    // MARK: - Deep Link Builder
    
    private func makeAcceptDeepLink(code: String) -> URL? { nil }
    
    // MARK: - Accept Invite Link
    
    func acceptInviteLink(url: URL) async {
        isAcceptingLink = true
        error = nil
        
        do {
            guard url.scheme == "rc", url.host == "invite" else { throw NSError(domain: "Pairing", code: -3) }
            let code = url.lastPathComponent
            guard let userId = supabase.currentUser?.id else { throw NSError(domain: "Pairing", code: -1) }
            _ = try await supabase.client.database
                .from("couples")
                .update(["partner_user_id": userId.uuidString, "invite_code": NSNull()])
                .eq("invite_code", value: code)
                .is("partner_user_id", value: nil)
                .select()
                .execute()
            await supabase.checkPairingStatus()
            isAcceptingLink = false
        } catch {
            self.error = "Failed to accept invite: \(error.localizedDescription)"
            isAcceptingLink = false
        }
    }
    
    // MARK: - Complete Pairing
    
    func completePairing() async { }
}

