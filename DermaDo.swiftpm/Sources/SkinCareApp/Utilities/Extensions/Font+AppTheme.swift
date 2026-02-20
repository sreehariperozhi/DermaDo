import SwiftUI

extension Font {
    // MARK: - New Semantic Styles
    static let appLargeTitle = Font(AppTypography.largeTitle)
    static let appSectionTitle = Font(AppTypography.sectionTitle)
    static let appBody = Font(AppTypography.body)
    static let appCaptionText = Font(AppTypography.captionText)

    // MARK: - Legacy Styles (backward compatibility)
    static let appDisplayLarge = Font(AppTypography.displayLarge)
    static let appDisplayMedium = Font(AppTypography.displayMedium)

    static let appHeading1 = Font(AppTypography.heading1)
    static let appHeading2 = Font(AppTypography.heading2)
    static let appHeading3 = Font(AppTypography.heading3)

    static let appBodyLarge = Font(AppTypography.bodyLarge)
    static let appBodyMedium = Font(AppTypography.bodyMedium)
    static let appBodySmall = Font(AppTypography.bodySmall)

    static let appLabelLarge = Font(AppTypography.labelLarge)
    static let appLabelMedium = Font(AppTypography.labelMedium)
    static let appLabelSmall = Font(AppTypography.labelSmall)

    static let appCaption = Font(AppTypography.caption)

    static let appNumericLarge = Font(AppTypography.numericLarge)
    static let appNumericSmall = Font(AppTypography.numericSmall)
}
