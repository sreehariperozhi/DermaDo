import SwiftUI

// MARK: - AppTypography Modifier

struct AppTypographyModifier: ViewModifier {
    let style: AppFontStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
    }
}

// MARK: - AppFontStyle Enum

enum AppFontStyle {
    // New semantic styles
    case largeTitle
    case sectionTitle
    case bodyText
    case captionText

    // Legacy styles
    case displayLarge
    case displayMedium
    case heading1
    case heading2
    case heading3
    case bodyLarge
    case bodyMedium
    case bodySmall
    case labelLarge
    case labelMedium
    case labelSmall
    case caption
    case numericLarge
    case numericSmall

    var font: Font {
        switch self {
        case .largeTitle: return .appLargeTitle
        case .sectionTitle: return .appSectionTitle
        case .bodyText: return .appBody
        case .captionText: return .appCaptionText
        case .displayLarge: return .appDisplayLarge
        case .displayMedium: return .appDisplayMedium
        case .heading1: return .appHeading1
        case .heading2: return .appHeading2
        case .heading3: return .appHeading3
        case .bodyLarge: return .appBodyLarge
        case .bodyMedium: return .appBodyMedium
        case .bodySmall: return .appBodySmall
        case .labelLarge: return .appLabelLarge
        case .labelMedium: return .appLabelMedium
        case .labelSmall: return .appLabelSmall
        case .caption: return .appCaption
        case .numericLarge: return .appNumericLarge
        case .numericSmall: return .appNumericSmall
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies the specified AppTypography style.
    func appFont(_ style: AppFontStyle) -> some View {
        self.modifier(AppTypographyModifier(style: style))
    }
}
