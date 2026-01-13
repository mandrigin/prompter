import SwiftUI

/// Royal Velvet inspired color theme
/// Based on Obsidian's Royal Velvet theme - deep purple/violet palette
enum Theme {
    // MARK: - Base Colors

    /// Deep purple background - primary app background
    static let background = Color(red: 0.118, green: 0.094, blue: 0.212)  // #1e1836

    /// Slightly lighter purple for secondary surfaces
    static let surface = Color(red: 0.157, green: 0.129, blue: 0.267)  // #282144

    /// Card/panel background
    static let card = Color(red: 0.196, green: 0.165, blue: 0.322)  // #322a52

    /// Elevated surface (popovers, menus)
    static let elevated = Color(red: 0.235, green: 0.200, blue: 0.376)  // #3c3360

    // MARK: - Accent Colors

    /// Primary accent - bright purple
    static let accent = Color(red: 0.655, green: 0.545, blue: 0.980)  // #a78bfa

    /// Secondary accent - lighter lavender
    static let accentLight = Color(red: 0.769, green: 0.710, blue: 0.992)  // #c4b5fd

    /// Tertiary accent - soft violet
    static let accentSoft = Color(red: 0.561, green: 0.451, blue: 0.851)  // #8f73d9

    // MARK: - Text Colors

    /// Primary text - high contrast
    static let textPrimary = Color(red: 0.937, green: 0.925, blue: 0.969)  // #efecf7

    /// Secondary text - muted
    static let textSecondary = Color(red: 0.702, green: 0.667, blue: 0.776)  // #b3aac6

    /// Tertiary text - subtle
    static let textTertiary = Color(red: 0.529, green: 0.490, blue: 0.620)  // #877d9e

    // MARK: - Semantic Colors

    /// Success/positive
    static let success = Color(red: 0.400, green: 0.851, blue: 0.573)  // #66d992

    /// Warning
    static let warning = Color(red: 0.976, green: 0.769, blue: 0.365)  // #f9c45d

    /// Error/danger
    static let error = Color(red: 0.976, green: 0.427, blue: 0.455)  // #f96d74

    // MARK: - Mode Colors (for prompt variants)

    /// Primary mode - royal blue-purple
    static let modePrimary = Color(red: 0.502, green: 0.502, blue: 0.976)  // #8080f9

    /// Strict mode - warm amber
    static let modeStrict = Color(red: 0.976, green: 0.667, blue: 0.365)  // #f9aa5d

    /// Exploratory mode - magenta-purple
    static let modeExploratory = Color(red: 0.851, green: 0.451, blue: 0.851)  // #d973d9

    // MARK: - Borders & Separators

    /// Border color
    static let border = Color(red: 0.298, green: 0.255, blue: 0.412)  // #4c4169

    /// Subtle separator
    static let separator = Color(red: 0.235, green: 0.200, blue: 0.337)  // #3c3356

    // MARK: - Gradients

    /// Main background gradient
    static let backgroundGradient = LinearGradient(
        colors: [background, surface],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Accent gradient for highlights
    static let accentGradient = LinearGradient(
        colors: [accent, accentSoft],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Sidebar gradient
    static let sidebarGradient = LinearGradient(
        colors: [
            Color(red: 0.137, green: 0.110, blue: 0.243),  // #231c3e
            Color(red: 0.098, green: 0.078, blue: 0.180)   // #19142e
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - View Modifiers

extension View {
    /// Apply the main background gradient
    func themedBackground() -> some View {
        self.background(Theme.backgroundGradient)
    }

    /// Apply card styling
    func themedCard() -> some View {
        self
            .background(Theme.card)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }

    /// Apply elevated surface styling
    func themedElevated() -> some View {
        self
            .background(Theme.elevated)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
