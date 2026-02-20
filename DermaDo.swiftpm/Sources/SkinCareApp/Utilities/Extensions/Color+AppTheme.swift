import SwiftUI

extension Color {
    // MARK: - Semantic Tokens (new)
    static let appBackgroundPrimary = Color(uiColor: AppColor.backgroundPrimary)
    static let appBackgroundSecondary = Color(uiColor: AppColor.backgroundSecondary)
    static let appCardBackground = Color(uiColor: AppColor.cardBackground)
    static let appAccentPrimary = Color(uiColor: AppColor.accentPrimary)
    static let appAccentSubtle = Color(uiColor: AppColor.accentSubtle)
    static let appAccentPressed = Color(uiColor: AppColor.accentPressed)
    static let appTextPrimary = Color(uiColor: AppColor.textPrimary)
    static let appTextSecondary = Color(uiColor: AppColor.textSecondary)
    static let appTextTertiary = Color(uiColor: AppColor.textTertiary)
    static let appDivider = Color(uiColor: AppColor.divider)

    // MARK: - Legacy Aliases (backward compatibility)
    static let appCream = Color(uiColor: AppColor.cream)
    static let appSand = Color(uiColor: AppColor.sand)
    static let appStone = Color(uiColor: AppColor.stone)
    static let appAccent = Color(uiColor: AppColor.accent)
    static let appAccentDark = Color(uiColor: AppColor.accentDark)
    static let appBackground = Color(uiColor: AppColor.background)
    static let appSurface = Color(uiColor: AppColor.surface)
    static let appSeparator = Color(uiColor: AppColor.separator)
    static let appSuccess = Color(uiColor: AppColor.success)
    static let appWarning = Color(uiColor: AppColor.warning)
    static let appError = Color(uiColor: AppColor.error)
    static let appShadow = Color(uiColor: AppColor.shadow)
}
