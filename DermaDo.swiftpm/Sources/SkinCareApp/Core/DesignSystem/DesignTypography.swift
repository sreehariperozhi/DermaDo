import SwiftUI

/// Luxury Fashion-Tech Typography System for DermaDo 2.0
public enum DesignTypography {
    
    // MARK: - Display & Editorial
    
    /// Massive editorial headers (e.g. "Your Evening Routine")
    public static let displayEditorial = Font.system(size: 34, weight: .semibold, design: .serif)
    
    /// Secondary editorial headers
    public static let headerEditorial = Font.system(size: 28, weight: .medium, design: .serif)
    
    
    // MARK: - Body & UI Components
    
    /// Primary view titles & large buttons
    public static let titleUI = Font.system(size: 22, weight: .semibold, design: .default)
    
    /// Standard reading text for descriptions/instructions
    public static let bodyUI = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Emphasized body text for key values (e.g. "Oil: 5")
    public static let bodyStrongUI = Font.system(size: 16, weight: .semibold, design: .default)
    
    /// Microscopic text, overlines, and labels (e.g. "STEP 1 / CLEANSER")
    public static let captionUI = Font.system(size: 12, weight: .medium, design: .default)
    
    /// Extremely small status indicators
    public static let microUI = Font.system(size: 10, weight: .bold, design: .default)
}

// MARK: - Typography Modifiers

public struct EditorialTrackingModifier: ViewModifier {
    public func body(content: Content) -> some View {
        // Tightly tracked for editorial headings
        content.tracking(-0.5)
    }
}

public struct CaptionTrackingModifier: ViewModifier {
    public func body(content: Content) -> some View {
        // Loosely tracked for uppercase small UI labels
        content.tracking(1.0).textCase(.uppercase)
    }
}

extension View {
    /// Applies tight tracking suitable for Display Editorial fonts
    public func editorialTracking() -> some View {
        self.modifier(EditorialTrackingModifier())
    }
    
    /// Applies loose tracking and uppercase styling suitable for micro UI elements
    public func captionTracking() -> some View {
        self.modifier(CaptionTrackingModifier())
    }
}
