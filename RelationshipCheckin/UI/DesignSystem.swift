//
//  DesignSystem.swift
//  RelationshipCheckin
//
//  Redesigned with Liquid Glass & Adaptive Dark Mode - 10/10/2025
//

import SwiftUI

enum DesignSystem {
    
    // MARK: - Adaptive Color System
    
    struct AdaptiveColor {
        let light: Color
        let dark: Color
        
        func color(for scheme: ColorScheme) -> Color {
            scheme == .dark ? dark : light
        }
    }
    
    // MARK: - Custom Color Palette
    enum Colors {
        // Primary palette - Fixed colors (always same)
        static let primaryPurple = Color(red: 92/255, green: 90/255, blue: 219/255) // #5c5adb
        static let primaryPurpleBright = Color(red: 112/255, green: 110/255, blue: 239/255) // Brighter for dark mode
        static let lightLavender = Color(red: 227/255, green: 224/255, blue: 249/255) // #e3e0f9
        static let deepNavy = Color(red: 43/255, green: 40/255, blue: 76/255) // #2b284c
        static let warmGold = Color(red: 216/255, green: 164/255, blue: 90/255) // #d8a45a
        static let warmGoldBright = Color(red: 236/255, green: 184/255, blue: 110/255) // Brighter for dark mode
        
        // Adaptive palette
        static let adaptiveBackground = AdaptiveColor(
            light: .white,
            dark: Color(red: 18/255, green: 18/255, blue: 22/255) // #121216 - Very dark blue-gray
        )
        
        static let adaptiveSecondaryBackground = AdaptiveColor(
            light: Color(red: 227/255, green: 224/255, blue: 249/255), // Light lavender
            dark: Color(red: 35/255, green: 33/255, blue: 58/255) // #23213a - Dark purple-slate
        )
        
        static let adaptiveCardBackground = AdaptiveColor(
            light: Color(red: 227/255, green: 224/255, blue: 249/255).opacity(0.3),
            dark: Color(red: 45/255, green: 43/255, blue: 68/255).opacity(0.5) // Dark purple with transparency
        )
        
        static let adaptiveTextPrimary = AdaptiveColor(
            light: Color(red: 43/255, green: 40/255, blue: 76/255), // Deep navy
            dark: Color(red: 240/255, green: 240/255, blue: 245/255) // #f0f0f5 - Off white
        )
        
        static let adaptiveTextSecondary = AdaptiveColor(
            light: Color(red: 92/255, green: 90/255, blue: 219/255).opacity(0.7), // Purple
            dark: Color(red: 180/255, green: 178/255, blue: 230/255) // #b4b2e6 - Light purple
        )
        
        static let adaptiveTextTertiary = AdaptiveColor(
            light: Color(red: 43/255, green: 40/255, blue: 76/255).opacity(0.5),
            dark: Color(red: 150/255, green: 150/255, blue: 165/255) // #9696a5 - Medium gray
        )
        
        static let adaptiveBorderGradientStart = AdaptiveColor(
            light: .white.opacity(0.8),
            dark: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.15) // Subtle light edge
        )
        
        static let adaptiveBorderGradientEnd = AdaptiveColor(
            light: .white.opacity(0.2),
            dark: Color(red: 255/255, green: 255/255, blue: 255/255).opacity(0.05)
        )
        
        static let adaptiveInputBackground = AdaptiveColor(
            light: Color(red: 227/255, green: 224/255, blue: 249/255).opacity(0.4),
            dark: Color(red: 45/255, green: 43/255, blue: 68/255).opacity(0.6)
        )
        
        // Semantic mappings - now using adaptive colors
        static let accent = primaryPurple
        static let accentBright = primaryPurpleBright // For dark mode accents
        
        // Mood colors - enhanced for dark mode visibility
        static let moodGreat = primaryPurple
        static let moodGreatDark = primaryPurpleBright
        static let moodOkay = warmGold
        static let moodOkayDark = warmGoldBright
        static let moodDifficult = deepNavy
        static let moodDifficultDark = Color(red: 83/255, green: 80/255, blue: 116/255) // Lighter navy
        
        // Helper function to get adaptive color
        static func background(for scheme: ColorScheme) -> Color {
            adaptiveBackground.color(for: scheme)
        }
        
        static func secondaryBackground(for scheme: ColorScheme) -> Color {
            adaptiveSecondaryBackground.color(for: scheme)
        }
        
        static func cardBackground(for scheme: ColorScheme) -> Color {
            adaptiveCardBackground.color(for: scheme)
        }
        
        static func textPrimary(for scheme: ColorScheme) -> Color {
            adaptiveTextPrimary.color(for: scheme)
        }
        
        static func textSecondary(for scheme: ColorScheme) -> Color {
            adaptiveTextSecondary.color(for: scheme)
        }
        
        static func textTertiary(for scheme: ColorScheme) -> Color {
            adaptiveTextTertiary.color(for: scheme)
        }
        
        static func borderGradientStart(for scheme: ColorScheme) -> Color {
            adaptiveBorderGradientStart.color(for: scheme)
        }
        
        static func borderGradientEnd(for scheme: ColorScheme) -> Color {
            adaptiveBorderGradientEnd.color(for: scheme)
        }
        
        static func inputBackground(for scheme: ColorScheme) -> Color {
            adaptiveInputBackground.color(for: scheme)
        }
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

// MARK: - Liquid Glass Card (Adaptive Dark Mode)

struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
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
                // Adaptive Liquid Glass
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .fill(DesignSystem.Colors.cardBackground(for: colorScheme))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.borderGradientStart(for: colorScheme),
                                        DesignSystem.Colors.borderGradientEnd(for: colorScheme)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: colorScheme == .dark ? 0.5 : 1
                            )
                    }
                    .shadow(
                        color: colorScheme == .dark 
                            ? DesignSystem.Colors.primaryPurpleBright.opacity(0.12)
                            : DesignSystem.Colors.primaryPurple.opacity(0.08),
                        radius: colorScheme == .dark ? 16 : 12,
                        x: 0,
                        y: 4
                    )
            }
    }
}

// MARK: - Modern Button Styles (Adaptive)

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            colors: colorScheme == .dark ? 
                                [DesignSystem.Colors.primaryPurpleBright, DesignSystem.Colors.primaryPurple] :
                                [DesignSystem.Colors.primaryPurple, DesignSystem.Colors.primaryPurple.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ) :
                        LinearGradient(
                            colors: [
                                DesignSystem.Colors.textTertiary(for: colorScheme),
                                DesignSystem.Colors.textTertiary(for: colorScheme)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(
                        color: colorScheme == .dark ?
                            DesignSystem.Colors.primaryPurpleBright.opacity(0.4) :
                            DesignSystem.Colors.primaryPurple.opacity(0.3),
                        radius: colorScheme == .dark ? 12 : 8,
                        x: 0,
                        y: 4
                    )
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.headline)
            .foregroundStyle(
                colorScheme == .dark ? 
                    DesignSystem.Colors.primaryPurpleBright : 
                    DesignSystem.Colors.primaryPurple
            )
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md, style: .continuous)
                            .strokeBorder(
                                (colorScheme == .dark ? 
                                    DesignSystem.Colors.primaryPurpleBright : 
                                    DesignSystem.Colors.primaryPurple).opacity(0.3),
                                lineWidth: 1
                            )
                    }
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Modern Text Field Style (Adaptive)

struct LiquidTextEditor: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    let placeholder: String
    var minHeight: CGFloat = 80
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            }
            
            TextEditor(text: $text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight)
        }
        .padding(DesignSystem.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm, style: .continuous)
                .fill(DesignSystem.Colors.inputBackground(for: colorScheme))
        }
    }
}

// MARK: - Mood Selector Component (Adaptive)

struct ModernMoodSelector: View {
    @Environment(\.colorScheme) var colorScheme
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
                                .fill(mood.adaptiveColor(for: colorScheme))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    if selectedMood == mood {
                                        Circle()
                                            .strokeBorder(
                                                colorScheme == .dark ? 
                                                    Color.white.opacity(0.8) : 
                                                    Color.white,
                                                lineWidth: 3
                                            )
                                            .shadow(color: mood.adaptiveColor(for: colorScheme).opacity(0.5), radius: 8)
                                            .matchedGeometryEffect(id: "selection", in: animation)
                                    }
                                }
                            
                            Image(systemName: mood.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                        
                        Text(mood.displayName)
                            .font(DesignSystem.Typography.caption)
                            .fontWeight(selectedMood == mood ? .semibold : .regular)
                            .foregroundStyle(
                                selectedMood == mood ? 
                                    DesignSystem.Colors.textPrimary(for: colorScheme) : 
                                    DesignSystem.Colors.textSecondary(for: colorScheme)
                            )
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header (Adaptive)

struct SectionHeader: View {
    @Environment(\.colorScheme) var colorScheme
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
                    .foregroundStyle(
                        colorScheme == .dark ? 
                            DesignSystem.Colors.accentBright : 
                            DesignSystem.Colors.accent
                    )
            }
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Spacer()
        }
    }
}

// MARK: - Empty State View (Adaptive)

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(DesignSystem.Colors.textTertiary(for: colorScheme))
            
            Text(title)
                .font(DesignSystem.Typography.title3)
                .foregroundStyle(DesignSystem.Colors.textPrimary(for: colorScheme))
            
            Text(subtitle)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

// MARK: - Loading View (Adaptive)

struct LoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(
                    colorScheme == .dark ? 
                        DesignSystem.Colors.accentBright : 
                        DesignSystem.Colors.accent
                )
            
            Text("Loading...")
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(DesignSystem.Colors.textSecondary(for: colorScheme))
        }
    }
}
