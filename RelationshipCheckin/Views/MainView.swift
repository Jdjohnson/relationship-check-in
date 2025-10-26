//
//  MainView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design with Custom Palette - 10/10/2025
//

import SwiftUI

struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = MainViewModel()
    @State private var showHistory = false
    @State private var showMorningEntry = false
    @State private var showEveningEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Compact header
                    headerSection
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.sm)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Partner's entry
                            partnerSection
                            
                            // Quick entry buttons
                            quickEntrySection
                            
                            // My status
                            if viewModel.myTodayEntry != nil {
                                myStatusSection
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(DesignSystem.Colors.accent)
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showHistory) {
                HistoryDrawerView()
            }
            .sheet(isPresented: $showMorningEntry) {
                EntryView(entryType: .morning)
            }
            .sheet(isPresented: $showEveningEntry) {
                EntryView(entryType: .evening)
            }
        }
        .tint(DesignSystem.Colors.accent)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("Today")
                .font(DesignSystem.Typography.largeTitle)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Text(Date(), style: .date)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Partner Section
    
    @ViewBuilder
    private var partnerSection: some View {
        if viewModel.isLoading {
            LiquidGlassCard {
                LoadingView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.lg)
            }
        } else if let partnerEntry = viewModel.partnerTodayEntry {
            partnerEntryCard(partnerEntry)
        } else {
            emptyPartnerCard
        }
    }
    
    private func partnerEntryCard(_ entry: DailyEntry) -> some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                // Header
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.accentBright : DesignSystem.Colors.accent)
                    
                    Text("From Your Partner")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                    
                    Spacer()
                }
                
                // Content grid
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if let morningNeed = entry.morningNeed {
                        compactField(icon: "sunrise.fill", text: morningNeed, color: colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                    }
                    
                    if let mood = entry.eveningMood {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            
                            Circle()
                                .fill(mood.adaptiveColor(for: colorScheme))
                                .frame(width: 16, height: 16)
                            
                            Text(mood.displayName)
                                .font(DesignSystem.Typography.subheadline)
                                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                        }
                    }
                    
                    if let gratitude = entry.gratitude {
                        compactField(icon: "sparkles", text: gratitude, color: colorScheme == .dark ? DesignSystem.Colors.accentBright : DesignSystem.Colors.accent)
                    }
                    
                    if let tomorrowGreat = entry.tomorrowGreat {
                        compactField(icon: "arrow.forward.circle", text: tomorrowGreat, color: colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                    }
                }
            }
        }
    }
    
    private func compactField(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                .lineLimit(2)
        }
    }
    
    private var emptyPartnerCard: some View {
        LiquidGlassCard {
            EmptyStateView(
                icon: "heart.slash",
                title: "Not yet",
                subtitle: "Waiting for partner's check-in"
            )
        }
    }
    
    // MARK: - Quick Entry Section
    
    private var quickEntrySection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Morning button
            Button {
                showMorningEntry = true
            } label: {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Morning")
                        .font(DesignSystem.Typography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                                .strokeBorder(
                                    (colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold).opacity(0.3),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .buttonStyle(.plain)
            
            // Evening button
            Button {
                showEveningEntry = true
            } label: {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Evening")
                        .font(DesignSystem.Typography.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                                .strokeBorder(
                                    (colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple).opacity(0.3),
                                    lineWidth: 1
                                )
                        }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - My Status Section
    
    private var myStatusSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)
            
            Text("You've checked in")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(DesignSystem.Colors.secondaryBackground(for: colorScheme).opacity(0.5))
        }
    }
}
