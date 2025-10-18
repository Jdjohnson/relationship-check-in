//
//  PairingView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct PairingView: View {
    @StateObject private var viewModel = PairingViewModel()
    @State private var showAcceptSheet = false
    @State private var inviteLinkText = ""
    
    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    DesignSystem.Colors.lightLavender.opacity(0.3),
                    DesignSystem.Colors.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Spacer()
                
                // Hero
                heroSection
                
                // Actions
                actionCards
                
                Spacer()
                
                if let error = viewModel.error {
                    errorBanner(error)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: $showAcceptSheet) {
            AcceptInviteSheet(
                viewModel: viewModel,
                inviteLinkText: $inviteLinkText,
                isPresented: $showAcceptSheet
            )
        }
    }
    
    // MARK: - Hero
    
    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryPurple)
                    .frame(width: 96, height: 96)
                    .shadow(color: DesignSystem.Colors.primaryPurple.opacity(0.3), radius: 20)
                
                Image(systemName: "heart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignSystem.Colors.pureWhite)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Daily Connection")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                
                Text("Share your day together")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Actions
    
    private var actionCards: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Create
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Circle()
                            .fill(DesignSystem.Colors.primaryPurple.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "link.circle.fill")
                                    .foregroundStyle(DesignSystem.Colors.primaryPurple)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create Invite")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("Start by inviting")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        Task { await viewModel.createInviteLink() }
                    } label: {
                        Text("Create Link")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isCreatingLink)
                }
            }
            
            // Divider
            HStack {
                Rectangle()
                    .fill(DesignSystem.Colors.textTertiary.opacity(0.3))
                    .frame(height: 1)
                Text("or")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Rectangle()
                    .fill(DesignSystem.Colors.textTertiary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Accept
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Circle()
                            .fill(DesignSystem.Colors.warmGold.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "envelope.circle.fill")
                                    .foregroundStyle(DesignSystem.Colors.warmGold)
                            }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accept Invite")
                                .font(DesignSystem.Typography.headline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text("Join your partner")
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button {
                        showAcceptSheet = true
                    } label: {
                        Text("Accept Link")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }
    
    private func errorBanner(_ error: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)
            Text(error)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.red)
        }
        .padding(DesignSystem.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(.red.opacity(0.1))
        }
    }
}

// MARK: - Accept Sheet

struct AcceptInviteSheet: View {
    @ObservedObject var viewModel: PairingViewModel
    @Binding var inviteLinkText: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Circle()
                        .fill(DesignSystem.Colors.warmGold.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "envelope.open.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(DesignSystem.Colors.warmGold)
                        }
                        .padding(.top, DesignSystem.Spacing.xxl)
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Paste Invite Link")
                            .font(DesignSystem.Typography.title2)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)
                        Text("From your partner")
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                    
                    TextField("https://...", text: $inviteLinkText)
                        .font(DesignSystem.Typography.body)
                        .padding(DesignSystem.Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                                .fill(DesignSystem.Colors.lightLavender.opacity(0.4))
                        }
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .focused($isFocused)
                    
                    Button {
                        if let url = URL(string: inviteLinkText) {
                            Task {
                                await viewModel.acceptInviteLink(url: url)
                                if viewModel.error == nil { isPresented = false }
                            }
                        }
                    } label: {
                        Text("Accept Invite")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(inviteLinkText.isEmpty || viewModel.isAcceptingLink)
                    
                    if let error = viewModel.error {
                        Text(error)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
