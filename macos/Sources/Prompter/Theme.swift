import SwiftUI

/// Royal Velvet inspired color theme with Opera browser polish and Things typography
/// Combines deep purple palette with clean, modern design language
enum Theme {
    // MARK: - Base Colors (Royal Velvet)

    /// Deep purple background
    static let background = Color(red: 0.106, green: 0.082, blue: 0.192)  // #1b1531

    /// Slightly lighter purple for surfaces
    static let surface = Color(red: 0.145, green: 0.118, blue: 0.251)  // #251e40

    /// Card/panel background
    static let card = Color(red: 0.180, green: 0.149, blue: 0.298)  // #2e264c

    /// Elevated surface (popovers, hover states)
    static let elevated = Color(red: 0.216, green: 0.180, blue: 0.345)  // #372e58

    // MARK: - Accent Colors

    /// Primary accent - vibrant purple
    static let accent = Color(red: 0.639, green: 0.525, blue: 0.976)  // #a386f9

    /// Light accent for highlights
    static let accentLight = Color(red: 0.769, green: 0.698, blue: 1.0)  // #c4b2ff

    /// Soft accent for subtle highlights
    static let accentSoft = Color(red: 0.533, green: 0.431, blue: 0.831)  // #886ed4

    // MARK: - Text Colors (Things-inspired hierarchy)

    /// Primary text - clean, high contrast
    static let textPrimary = Color(red: 0.953, green: 0.945, blue: 0.976)  // #f3f1f9

    /// Secondary text - softer, supporting
    static let textSecondary = Color(red: 0.714, green: 0.682, blue: 0.784)  // #b6aec8

    /// Tertiary text - subtle, hints
    static let textTertiary = Color(red: 0.533, green: 0.502, blue: 0.624)  // #88809f

    // MARK: - Semantic Colors

    /// Success state
    static let success = Color(red: 0.380, green: 0.839, blue: 0.561)  // #61d68f

    /// Warning state
    static let warning = Color(red: 0.976, green: 0.757, blue: 0.345)  // #f9c158

    /// Error state
    static let error = Color(red: 0.969, green: 0.412, blue: 0.439)  // #f76970

    // MARK: - Borders & Separators

    /// Border color
    static let border = Color(red: 0.275, green: 0.235, blue: 0.384)  // #463c62

    /// Subtle separator
    static let separator = Color(red: 0.220, green: 0.188, blue: 0.314)  // #383050

    // MARK: - Gradients (Opera-inspired subtle depth)

    /// Main background gradient - subtle top-to-bottom
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.122, green: 0.094, blue: 0.216),  // #1f1837
            Color(red: 0.094, green: 0.071, blue: 0.169)   // #181229
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Sidebar gradient - slightly different tone
    static let sidebarGradient = LinearGradient(
        colors: [
            Color(red: 0.129, green: 0.102, blue: 0.224),  // #211a39
            Color(red: 0.098, green: 0.075, blue: 0.176)   // #19132d
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card hover gradient
    static let cardHoverGradient = LinearGradient(
        colors: [elevated, card],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Accent glow for focus states
    static let accentGlow = Color(red: 0.639, green: 0.525, blue: 0.976).opacity(0.3)

    // MARK: - Chip Colors (Fun, colorful template buttons)

    /// Colorful palette for template chips - complements Royal Velvet
    static let chipColors: [(base: Color, highlight: Color)] = [
        // Lavender Dream
        (Color(red: 0.565, green: 0.463, blue: 0.906), Color(red: 0.694, green: 0.608, blue: 0.969)),
        // Rose Quartz
        (Color(red: 0.878, green: 0.478, blue: 0.612), Color(red: 0.933, green: 0.624, blue: 0.718)),
        // Ocean Teal
        (Color(red: 0.329, green: 0.663, blue: 0.702), Color(red: 0.451, green: 0.749, blue: 0.780)),
        // Sunset Gold
        (Color(red: 0.925, green: 0.682, blue: 0.392), Color(red: 0.957, green: 0.773, blue: 0.525)),
        // Mint Fresh
        (Color(red: 0.467, green: 0.796, blue: 0.667), Color(red: 0.580, green: 0.855, blue: 0.745)),
        // Berry Burst
        (Color(red: 0.714, green: 0.400, blue: 0.675), Color(red: 0.808, green: 0.529, blue: 0.761)),
        // Sky Blue
        (Color(red: 0.447, green: 0.588, blue: 0.882), Color(red: 0.576, green: 0.702, blue: 0.933)),
        // Coral Reef
        (Color(red: 0.937, green: 0.522, blue: 0.463), Color(red: 0.965, green: 0.659, blue: 0.608)),
    ]

    /// Get a chip color pair based on index (cycles through palette)
    static func chipColor(for index: Int) -> (base: Color, highlight: Color) {
        chipColors[index % chipColors.count]
    }

    // MARK: - Typography (Things-inspired)

    /// Title font - clean, confident
    static func titleFont(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    /// Headline font - clear hierarchy
    static func headlineFont(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    /// Body font - readable, comfortable
    static func bodyFont(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// Caption font - supporting text
    static func captionFont(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    /// Mono font - for code/technical content
    static func monoFont(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing (Things-inspired generous spacing)

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // MARK: - Corner Radii (Opera-inspired smooth curves)

    static let radiusS: CGFloat = 6
    static let radiusM: CGFloat = 10
    static let radiusL: CGFloat = 14
    static let radiusXL: CGFloat = 18
}

// MARK: - View Modifiers

extension View {
    /// Apply themed card styling with Opera-like polish
    func themedCard(isHovered: Bool = false) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .fill(isHovered ? Theme.elevated : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .stroke(isHovered ? Theme.accent.opacity(0.3) : Theme.border, lineWidth: 1)
            )
    }

    /// Apply themed input field styling
    func themedInput(isFocused: Bool = false) -> some View {
        self
            .background(Theme.card)
            .cornerRadius(Theme.radiusM)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM)
                    .stroke(isFocused ? Theme.accent : Theme.border, lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: isFocused ? Theme.accentGlow : .clear, radius: 8, x: 0, y: 0)
    }

    /// Apply Things-like generous padding
    func thingsSpacing() -> some View {
        self.padding(Theme.spacingL)
    }
}
