import Foundation
import Supabase
import SwiftUI

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    @Published var session: Session?
    @Published var isInitializing = true
    @Published var currentUser: User?
    @Published var coupleId: UUID?
    @Published var partnerId: UUID?
    @Published var isPaired = false
    @Published var error: Error?
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        Task {
            await initialize()
        }
    }
    
    func initialize() async {
        do {
            if let session = try? await client.auth.session {
                self.session = session
                self.currentUser = session.user
                await checkPairingStatus()
            }
            
            for await (_, session) in await client.auth.authStateChanges {
                self.session = session
                self.currentUser = session?.user
                if session != nil {
                    await checkPairingStatus()
                } else {
                    self.isPaired = false
                    self.coupleId = nil
                    self.partnerId = nil
                }
            }
        } catch {
            self.error = error
        }
        
        isInitializing = false
    }
    
    func checkPairingStatus() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let couples: [Couple] = try await client.database
                .from("couples")
                .select()
                .or("owner_user_id.eq.\(userId),partner_user_id.eq.\(userId)")
                .execute()
                .value
            
            if let couple = couples.first {
                self.coupleId = couple.id
                self.isPaired = couple.partnerUserId != nil
                self.partnerId = couple.ownerUserId == userId ? couple.partnerUserId : couple.ownerUserId
            } else {
                self.isPaired = false
                self.coupleId = nil
                self.partnerId = nil
            }
        } catch {
            self.error = error
        }
    }
}

struct Couple: Codable {
    let id: UUID
    let ownerUserId: UUID
    let partnerUserId: UUID?
    let inviteCode: UUID?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerUserId = "owner_user_id"
        case partnerUserId = "partner_user_id"
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}

struct DailyEntryDB: Codable {
    let id: UUID
    let coupleId: UUID
    let authorUserId: UUID
    let date: Date
    let morningNeed: String?
    let eveningMood: Int?
    let gratitude: String?
    let tomorrowGreat: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case coupleId = "couple_id"
        case authorUserId = "author_user_id"
        case date
        case morningNeed = "morning_need"
        case eveningMood = "evening_mood"
        case gratitude
        case tomorrowGreat = "tomorrow_great"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}


