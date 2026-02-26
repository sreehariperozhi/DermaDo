import SwiftUI

/// Luxury Fashion-Tech Color Palette for DermaDo 2.0
/// Background and text colors adapt to light/dark mode.
public enum DesignColors {
    
    // MARK: - The Void (Backgrounds / Surfaces) — Adaptive
    
    /// Absolute background. Adapts: dark → deepest black, light → warm off-white.
    public static let voidObsidian = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "#050505") : UIColor(hex: "#F5F3F0")
    })
    
    /// Elevated cards and standard surfaces. Adapts for both modes.
    public static let voidCharcoal = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "#121212") : UIColor(hex: "#FFFFFF")
    })
    
    /// Highest elevation, input fields, pressed states. Adapts for both modes.
    public static let voidAsh = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "#1C1C1E") : UIColor(hex: "#E8E5E0")
    })
    
    
    // MARK: - The Cosmetics (Primary Accents / Text) — Adaptive
    
    /// Primary text. Adapts: dark → soft white, light → near black.
    public static let luminousPearl = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "#F8F8F2") : UIColor(hex: "#1A1A1A")
    })
    
    /// Primary interactive color, signifies luxury/skin.
    public static let roseGold = Color(hex: "#E0A96D")
    
    /// Secondary text, inactive states, subtle dividers. Adapts for readability.
    public static let liquidSilver = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(hex: "#BFBAB3") : UIColor(hex: "#6B6560")
    })
    
    /// Default skin tone for the avatar base
    public static let sandalwoodMedium = Color(hex: "#D2A28A")
    
    
    // MARK: - The Elements (Semantic & Status) — Constant
    
    /// For moisturizers / toners / water elements.
    public static let ceruleanHydration = Color(hex: "#5B8FB9")
    
    /// For natural ingredients, success states.
    public static let sageBotanical = Color(hex: "#769F72")
    
    /// For irritation mapping, destructive actions.
    public static let velvetCrimson = Color(hex: "#A63D40")
}

// MARK: - HEX Initializer Exentsion
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}


