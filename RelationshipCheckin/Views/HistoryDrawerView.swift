//
//  HistoryDrawerView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct HistoryDrawerView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = HistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Date picker
                        LiquidGlassCard(padding: DesignSystem.Spacing.sm) {
                            DatePicker(
                                "Select Date",
                                selection: $viewModel.selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .tint(DesignSystem.Colors.accent)
                            .onChange(of: viewModel.selectedDate) { _, newDate in
                                Task { await viewModel.loadEntries(for: newDate) }
                            }
                        }
                        
                        // Entries
                        if viewModel.isLoading {
                            LiquidGlassCard {
                                LoadingView()
                                    .padding(.vertical, DesignSystem.Spacing.lg)
                            }
                        } else {
                            if let partnerEntry = viewModel.partnerEntry {
                                entryCard(partnerEntry, isPartner: true)
                            } else {
                                emptyCard(isPartner: true)
                            }
                            
                            if let myEntry = viewModel.myEntry {
                                entryCard(myEntry, isPartner: false)
                            } else {
                                emptyCard(isPartner: false)
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.accent)
                        .fontWeight(.semibold)
                }
            }
            .task {
                await viewModel.loadEntries(for: viewModel.selectedDate)
            }
        }
    }
    
    private func entryCard(_ entry: DailyEntry, isPartner: Bool) -> some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: isPartner ? "heart.fill" : "person.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            isPartner ? 
                                (colorScheme == .dark ? DesignSystem.Colors.accentBright : DesignSystem.Colors.accent) :
                                (colorScheme == .dark ? DesignSystem.Colors.warmGoldBright : DesignSystem.Colors.warmGold)
                        )
                    
                    Text(isPartner ? "Partner" : "You")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    if let morningNeed = entry.morningNeed {
                        compactField(icon: "sunrise.fill", text: morningNeed)
                    }
                    
                    if let mood = entry.eveningMood {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(colorScheme == .dark ? DesignSystem.Colors.primaryPurpleBright : DesignSystem.Colors.primaryPurple)
                            Circle()
                                .fill(mood.adaptiveColor(for: colorScheme))
                                .frame(width: 12, height: 12)
                            Text(mood.displayName)
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                        }
                    }
                    
                    if let gratitude = entry.gratitude {
                        compactField(icon: "sparkles", text: gratitude)
                    }
                    
                    if let tomorrowGreat = entry.tomorrowGreat {
                        compactField(icon: "arrow.forward.circle", text: tomorrowGreat)
                    }
                }
            }
        }
    }
    
    private func compactField(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            Text(text)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                .lineLimit(2)
        }
    }
    
    private func emptyCard(isPartner: Bool) -> some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
                Text(isPartner ? "Partner didn't check in" : "You didn't check in")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
            }
        }
    }
}
