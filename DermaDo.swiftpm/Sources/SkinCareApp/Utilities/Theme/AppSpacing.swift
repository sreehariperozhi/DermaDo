import UIKit

// MARK: - AppSpacing
/// 8pt grid spacing system for consistent layout rhythm.
/// All values are multiples of the 4pt base unit (following the 8pt major grid).
enum AppSpacing {

    // MARK: - Base Unit

    /// 4pt — the smallest increment; used for fine optical adjustments.
    static let xxs: CGFloat = 4

    /// 8pt — primary small spacing; icon gutters, tight padding.
    static let xs: CGFloat = 8

    /// 12pt — between tightly-related elements within a card.
    static let sm: CGFloat = 12

    /// 16pt — default intra-component spacing; standard padding.
    static let md: CGFloat = 16

    /// 20pt — between related components in a group.
    static let lg: CGFloat = 20

    /// 24pt — section padding, card internal margins.
    static let xl: CGFloat = 24

    /// 32pt — between major sections.
    static let xxl: CGFloat = 32

    /// 40pt — top/bottom screen margins, hero spacing.
    static let xxxl: CGFloat = 40

    // MARK: - Screen Edge

    /// Horizontal padding from screen edges.
    static let screenHorizontal: CGFloat = 20

    /// Vertical padding from safe-area edges.
    static let screenVertical: CGFloat = 16

    // MARK: - Card

    /// Internal padding inside card components.
    static let cardPadding: CGFloat = 18

    /// Spacing between stacked cards.
    static let cardGap: CGFloat = 16

    // MARK: - Corner Radius

    /// Small radius for buttons, text fields.
    static let radiusSmall: CGFloat = 10

    /// Medium radius for cards, sheets.
    static let radiusMedium: CGFloat = 16

    /// Large radius for feature cards, hero sections (18–22 range).
    static let radiusLarge: CGFloat = 20

    /// Full radius for pills, avatars.
    static let radiusFull: CGFloat = 9999

    // MARK: - Shadow (ultra-subtle, light mode only)

    /// Standard soft shadow configuration.
    static let shadowRadius: CGFloat = 8
    static let shadowOffset = CGSize(width: 0, height: 2)
    static let shadowOpacity: Float = 0.05
}
