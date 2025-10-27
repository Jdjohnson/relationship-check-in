import Foundation
import Supabase
import SwiftUI

@MainActor
class AuthService: ObservableObject {
    private let supabase = SupabaseService.shared
    
    @Published var isLoading = false
    @Published var error: String?
    
    func signUp(email: String, password: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            _ = try await supabase.client.auth.signUp(
                email: email,
                password: password
            )
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            _ = try await supabase.client.auth.signIn(
                email: email,
                password: password
            )
            isLoading = false
            return true
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signOut() async {
        do {
            try await supabase.client.auth.signOut()
        } catch {
            self.error = error.localizedDescription
        }
    }
}


