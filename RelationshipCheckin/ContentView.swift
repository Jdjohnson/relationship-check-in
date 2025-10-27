//
//  ContentView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @EnvironmentObject var deepLinkService: DeepLinkService
    
    var body: some View {
        Group {
            if supabaseService.isInitializing {
                LoadingScreen()
            } else if supabaseService.session == nil {
                LoginView()
            } else if !supabaseService.isPaired {
                PairingView()
            } else {
                MainView()
            }
        }
        .sheet(item: $deepLinkService.activeRoute) { route in
            NavigationStack {
                EntryView(entryType: route.entryType)
            }
        }
    }
}

struct LoadingScreen: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignSystem.Colors.secondaryBackground(for: colorScheme).opacity(0.3),
                    DesignSystem.Colors.background(for: colorScheme)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryPurple)
                        .frame(width: 80, height: 80)
                        .shadow(color: DesignSystem.Colors.primaryPurple.opacity(0.3), radius: 20)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
                
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignSystem.Colors.accent)
                
                Text("Setting up...")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            }
        }
    }
}
