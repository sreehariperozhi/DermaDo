import SwiftUI
import UIKit

// MARK: - AppColor
/// Adaptive color palette for a minimal, gender-neutral skincare app.
/// All colors automatically adapt between light and dark mode.
/// Uses semantic token naming for clear intent.
enum AppColor {

    // MARK: - Semantic Background Tokens

    /// Primary background — deepest layer behind all content.
    /// Light: warm ivory. Dark: deep charcoal (no pure black).
    static let backgroundPrimary = adaptive(
        light: UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1.0),   // #FAF8F2
        dark:  UIColor(red: 0.10, green: 0.10, blue: 0.11, alpha: 1.0)    // #1A1A1C
    )

    /// Secondary background — elevated surfaces, grouped content areas.
    static let backgroundSecondary = adaptive(
        light: UIColor(red: 0.96, green: 0.94, blue: 0.91, alpha: 1.0),   // #F5F0E8
        dark:  UIColor(red: 0.13, green: 0.13, blue: 0.14, alpha: 1.0)    // #222224
    )

    /// Card and container fill.
    static let cardBackground = adaptive(
        light: UIColor.white,
        dark:  UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)    // #2C2C2E
    )

    // MARK: - Accent Tokens

    /// Primary accent — interactive elements, buttons, links.
    static let accentPrimary = adaptive(
        light: UIColor(red: 0.47, green: 0.56, blue: 0.65, alpha: 1.0),   // #788FA6
        dark:  UIColor(red: 0.55, green: 0.65, blue: 0.76, alpha: 1.0)    // #8CA6C2
    )

    /// Subtle accent — very low opacity accent for backgrounds, badges.
    static let accentSubtle = adaptive(
        light: UIColor(red: 0.47, green: 0.56, blue: 0.65, alpha: 0.12),
        dark:  UIColor(red: 0.55, green: 0.65, blue: 0.76, alpha: 0.15)
    )

    /// Deeper accent — pressed / active state.
    static let accentPressed = adaptive(
        light: UIColor(red: 0.35, green: 0.44, blue: 0.54, alpha: 1.0),   // #59708A
        dark:  UIColor(red: 0.45, green: 0.55, blue: 0.66, alpha: 1.0)    // #738CA8
    )

    // MARK: - Text Tokens

    /// Primary text — near-black in light, soft off-white in dark (not pure white).
    static let textPrimary = adaptive(
        light: UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0),   // #212121
        dark:  UIColor(red: 0.93, green: 0.93, blue: 0.92, alpha: 1.0)    // #EDEDEB
    )

    /// Secondary text — captions, subtitles.
    static let textSecondary = adaptive(
        light: UIColor(red: 0.45, green: 0.43, blue: 0.40, alpha: 1.0),   // #736E66
        dark:  UIColor(red: 0.65, green: 0.63, blue: 0.60, alpha: 1.0)    // #A6A099
    )

    /// Tertiary text — placeholders, disabled text.
    static let textTertiary = adaptive(
        light: UIColor(red: 0.62, green: 0.60, blue: 0.57, alpha: 1.0),   // #9E9991
        dark:  UIColor(red: 0.50, green: 0.48, blue: 0.45, alpha: 1.0)    // #807A73
    )

    // MARK: - Divider

    /// Separator / divider lines.
    static let divider = adaptive(
        light: UIColor(red: 0.88, green: 0.86, blue: 0.83, alpha: 1.0),   // #E0DBD4
        dark:  UIColor(red: 0.22, green: 0.22, blue: 0.23, alpha: 1.0)    // #38383A
    )

    // MARK: - Legacy Brand Tokens (kept for backward compatibility)

    static let cream = backgroundSecondary
    static let sand = adaptive(
        light: UIColor(red: 0.98, green: 0.96, blue: 0.94, alpha: 1.0),   // #FAF5F0
        dark:  UIColor(red: 0.18, green: 0.18, blue: 0.19, alpha: 1.0)    // #2E2E30
    )
    static let stone = adaptive(
        light: UIColor(red: 0.85, green: 0.82, blue: 0.78, alpha: 1.0),   // #D9D1C7
        dark:  UIColor(red: 0.30, green: 0.29, blue: 0.28, alpha: 1.0)    // #4D4A47
    )

    // Legacy aliases
    static let accent = accentPrimary
    static let accentDark = accentPressed
    static let background = backgroundPrimary
    static let surface = cardBackground
    static let separator = divider

    // MARK: - Status Colors

    static let success = adaptive(
        light: UIColor(red: 0.42, green: 0.67, blue: 0.53, alpha: 1.0),   // #6BAB87
        dark:  UIColor(red: 0.48, green: 0.73, blue: 0.59, alpha: 1.0)    // #7ABA96
    )

    static let warning = adaptive(
        light: UIColor(red: 0.85, green: 0.70, blue: 0.40, alpha: 1.0),   // #D9B366
        dark:  UIColor(red: 0.90, green: 0.76, blue: 0.46, alpha: 1.0)    // #E6C275
    )

    static let error = adaptive(
        light: UIColor(red: 0.80, green: 0.42, blue: 0.42, alpha: 1.0),   // #CC6B6B
        dark:  UIColor(red: 0.85, green: 0.50, blue: 0.50, alpha: 1.0)    // #D98080
    )

    // MARK: - Shadows

    /// Shadow color — ultra-subtle in light mode, clear in dark mode.
    static let shadow = adaptive(
        light: UIColor.black.withAlphaComponent(0.05),
        dark:  UIColor.clear
    )

    // MARK: - Private Helpers

    private static func adaptive(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}
