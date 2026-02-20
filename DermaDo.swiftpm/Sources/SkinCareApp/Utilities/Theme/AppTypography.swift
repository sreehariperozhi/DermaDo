import SwiftUI
import UIKit

// MARK: - AppTypography
/// Type scale using SF Pro (system font) with semantic naming.
/// All sizes use UIFontMetrics for Dynamic Type support.
enum AppTypography {

    // MARK: - New Semantic Hierarchy

    /// 30pt Semibold — screen titles, hero headings.
    static var largeTitle: UIFont {
        let font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }

    /// 21pt Medium — section headers, card titles.
    static var sectionTitle: UIFont {
        let font = UIFont.systemFont(ofSize: 21, weight: .medium)
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: font)
    }

    /// 16pt Regular — primary body text.
    static var body: UIFont {
        let font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// 13pt Regular — captions, footnotes.
    static var captionText: UIFont {
        let font = UIFont.systemFont(ofSize: 13, weight: .regular)
        return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: font)
    }

    // MARK: - Display (legacy compatible)

    /// 32pt Semibold (scaled) — hero headings, onboarding titles.
    static var displayLarge: UIFont {
        let font = UIFont.systemFont(ofSize: 32, weight: .semibold)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: font)
    }

    /// 28pt Semibold (scaled) — screen titles.
    static var displayMedium: UIFont {
        let font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: font)
    }

    // MARK: - Headings

    /// 24pt Semibold (scaled) — section headers on major screens.
    static var heading1: UIFont {
        let font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return UIFontMetrics(forTextStyle: .title2).scaledFont(for: font)
    }

    /// 20pt Medium (scaled) — card titles, sub-section headers.
    static var heading2: UIFont {
        let font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return UIFontMetrics(forTextStyle: .title3).scaledFont(for: font)
    }

    /// 17pt Medium (scaled) — list row headlines.
    static var heading3: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return UIFontMetrics(forTextStyle: .headline).scaledFont(for: font)
    }

    // MARK: - Body

    /// 17pt Regular (scaled) — primary body text.
    static var bodyLarge: UIFont {
        let font = UIFont.systemFont(ofSize: 17, weight: .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// 15pt Regular (scaled) — secondary body, descriptions.
    static var bodyMedium: UIFont {
        let font = UIFont.systemFont(ofSize: 15, weight: .regular)
        return UIFontMetrics(forTextStyle: .callout).scaledFont(for: font)
    }

    /// 13pt Regular (scaled) — supporting text, metadata.
    static var bodySmall: UIFont {
        let font = UIFont.systemFont(ofSize: 13, weight: .regular)
        return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font)
    }

    // MARK: - Labels

    /// 15pt Medium (scaled) — button text, form labels.
    static var labelLarge: UIFont {
        let font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: font)
    }

    /// 13pt Medium (scaled) — tags, badges, small buttons.
    static var labelMedium: UIFont {
        let font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: font)
    }

    /// 11pt Medium (scaled) — micro labels, timestamps.
    static var labelSmall: UIFont {
        let font = UIFont.systemFont(ofSize: 11, weight: .medium)
        return UIFontMetrics(forTextStyle: .caption2).scaledFont(for: font)
    }

    // MARK: - Captions

    /// 12pt Regular (scaled) — captions, footnotes.
    static var caption: UIFont {
        let font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: font)
    }

    // MARK: - Monospaced (for numeric data)

    /// 17pt Monospaced (scaled) — numeric values, counters.
    static var numericLarge: UIFont {
        let font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .semibold)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: font)
    }

    /// 13pt Monospaced (scaled) — small counters, percentages.
    static var numericSmall: UIFont {
        let font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        return UIFontMetrics(forTextStyle: .footnote).scaledFont(for: font)
    }
}
