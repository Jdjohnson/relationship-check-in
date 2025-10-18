//
//  DesignSystem.swift
//  RelationshipCheckin
//
//  Redesigned with Liquid Glass & Custom Palette - 10/10/2025
//

import SwiftUI

enum DesignSystem {
    
    // MARK: - Custom Color Palette
    enum Colors {
        // Primary palette
        static let primaryPurple = Color(red: 92/255, green: 90/255, blue: 219/255) // #5c5adb
        static let lightLavender = Color(red: 227/255, green: 224/255, blue: 249/255) // #e3e0f9
        static let deepNavy = Color(red: 43/255, green: 40/255, blue: 76/255) // #2b284c
        static let warmGold = Color(red: 216/255, green: 164/255, blue: 90/255) // #d8a45a
        static let pureWhite = Color.white // #ffffff
        
        // Semantic mappings
        static let accent = primaryPurple
        static let background = pureWhite
        static let secondaryBackground = lightLavender
        static let textPrimary = deepNavy
        static let textSecondary = primaryPurple.opacity(0.7)
        static let textTertiary = deepNavy.opacity(0.5)
        
        // Mood colors - using palette
        static let moodGreat = primaryPurple
        static let moodOkay = warmGold
        static let moodDifficult = deepNavy
    }
    
    // MARK: - Typography (San Francisco)
    enum Typography {
        // San Francisco is the default system font
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title1 = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .semibold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
    }
    
    // MARK: - Animations
    enum Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Liquid Glass Card (True iOS 18+ Liquid Glass)

struct LiquidGlassCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DesignSystem.Spacing.lg
    
    init(padding: CGFloat = DesignSystem.Spacing.lg, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                // True Liquid Glass: thin material with subtle tint
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .fill(DesignSystem.Colors.lightLavender.opacity(0.3))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.pureWhite.opacity(0.8),
                                        DesignSystem.Colors.pureWhite.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                    .shadow(color: DesignSystem.Colors.primaryPurple.opacity(0.08), radius: 12, x: 0, y: 4)
            }
    }
}

// MARK: - Modern Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(DesignSystem.Colors.pureWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            colors: [DesignSystem.Colors.primaryPurple, DesignSystem.Colors.primaryPurple.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [DesignSystem.Colors.textTertiary, DesignSystem.Colors.textTertiary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: DesignSystem.Colors.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(DesignSystem.Colors.primaryPurple)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .strokeBorder(DesignSystem.Colors.primaryPurple.opacity(0.3), lineWidth: 1)
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Modern Text Field Style

struct LiquidTextEditor: View {
    @Binding var text: String
    let placeholder: String
    var minHeight: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(DesignSystem.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(DesignSystem.Colors.lightLavender.opacity(0.4))
        }
    }
}

// MARK: - Mood Selector Component

struct ModernMoodSelector: View {
    @Binding var selectedMood: Mood?
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Button {
                    withAnimation(DesignSystem.Animation.spring) {
                        selectedMood = mood
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                } label: {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(mood.color)
                                .frame(width: 56, height: 56)
                                .overlay {
                                    if selectedMood == mood {
                                        Circle()
                                            .strokeBorder(DesignSystem.Colors.pureWhite, lineWidth: 3)
                                            .shadow(color: mood.color.opacity(0.5), radius: 8)
                                            .matchedGeometryEffect(id: "selection", in: animation)
                                    }
                                }
                            
                            Image(systemName: mood.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(DesignSystem.Colors.pureWhite)
                        }
                        
                        Text(mood.displayName)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(selectedMood == mood ? .semibold : .regular)
                            .foregroundStyle(selectedMood == mood ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(DesignSystem.Typography.callout)
                    .foregroundStyle(DesignSystem.Colors.accent)
            }
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            Text(subtitle)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(DesignSystem.Colors.accent)
            
            Text("Loading...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }
}
