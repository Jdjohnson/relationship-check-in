//
//  EntryView.swift
//  RelationshipCheckin
//
//  Liquid Glass Design - 10/10/2025
//

import SwiftUI

struct EntryView: View {
    @StateObject private var viewModel: EntryViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case morningNeed, gratitude, tomorrowGreat
    }
    
    init(entryType: EntryType) {
        _viewModel = StateObject(wrappedValue: EntryViewModel(entryType: entryType))
    }
    
    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Compact hero
                heroHeader
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        if viewModel.entryType == .morning {
                            morningContent
                        } else {
                            eveningContent
                        }
                        
                        saveButton
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            
            if viewModel.showSuccess {
                successOverlay
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(viewModel.entryType == .morning ? DesignSystem.Colors.warmGold : DesignSystem.Colors.primaryPurple)
                    .frame(width: 64, height: 64)
                
                Image(systemName: viewModel.entryType == .morning ? "sunrise.fill" : "moon.stars.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(DesignSystem.Colors.pureWhite)
            }
            
            Text(viewModel.entryType == .morning ? "Morning Check-in" : "Evening Check-in")
                .font(DesignSystem.Typography.title2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            Text(Date(), style: .date)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Morning Content
    
    private var morningContent: some View {
        LiquidGlassCard(padding: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                SectionHeader("What do you need today?", icon: "heart.fill")
                
                LiquidTextEditor(
                    text: $viewModel.morningNeed,
                    placeholder: "I need...",
                    minHeight: 100
                )
            }
        }
    }
    
    // MARK: - Evening Content
    
    private var eveningContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Mood
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SectionHeader("How was your day?", icon: "face.smiling")
                    ModernMoodSelector(selectedMood: $viewModel.eveningMood)
                }
            }
            
            // Gratitude
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SectionHeader("Grateful for", icon: "sparkles")
                    LiquidTextEditor(
                        text: $viewModel.gratitude,
                        placeholder: "I'm thankful for...",
                        minHeight: 70
                    )
                }
            }
            
            // Tomorrow
            LiquidGlassCard(padding: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    SectionHeader("Make tomorrow great", icon: "arrow.forward.circle")
                    LiquidTextEditor(
                        text: $viewModel.tomorrowGreat,
                        placeholder: "Tomorrow will be great if...",
                        minHeight: 70
                    )
                }
            }
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.saveEntry()
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(DesignSystem.Colors.pureWhite)
                }
                Text(viewModel.showSuccess ? "Saved!" : "Save Check-in")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!viewModel.canSave || viewModel.isSaving || viewModel.showSuccess)
    }
    
    // MARK: - Success Overlay
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryPurple)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(DesignSystem.Colors.pureWhite)
                }
                
                Text("Saved!")
                    .font(DesignSystem.Typography.title1)
                    .foregroundStyle(DesignSystem.Colors.pureWhite)
            }
            .padding(DesignSystem.Spacing.xxl)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl, style: .continuous)
                    .fill(.ultraThickMaterial)
            }
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
}
