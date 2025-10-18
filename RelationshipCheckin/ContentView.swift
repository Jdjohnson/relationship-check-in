//
//  ContentView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @EnvironmentObject var deepLinkService: DeepLinkService
    
    var body: some View {
        Group {
            if cloudKitService.isInitializing {
                LoadingScreen()
            } else if !cloudKitService.isPaired {
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
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    DesignSystem.Colors.lightLavender.opacity(0.3),
                    DesignSystem.Colors.background
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
                        .foregroundStyle(DesignSystem.Colors.pureWhite)
                }
                
                ProgressView()
                    .controlSize(.large)
                    .tint(DesignSystem.Colors.accent)
                
                Text("Setting up...")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
}
