import SwiftUI

/// Standardizes the hover/selection interaction for cards and list items.
public struct CardHoverModifier: ViewModifier {
    let isActive: Bool
    let anyCardSelected: Bool
    
    public init(isActive: Bool, anyCardSelected: Bool) {
        self.isActive = isActive
        self.anyCardSelected = anyCardSelected
    }
    
    public func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.02 : 1.0)
            .opacity(anyCardSelected ? (isActive ? 1.0 : 0.4) : 1.0)
            // If active, increase the ambient glow intensity
            .shadow(color: DesignColors.roseGold.opacity(isActive ? 0.3 : 0), radius: 32, x: 0, y: 12)
            .animation(Animation.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
            .animation(Animation.spring(response: 0.5, dampingFraction: 0.8), value: anyCardSelected)
    }
}

// Convenience extension
extension View {
    /// Applies the DermaDo 2.0 Focus Shift selection animation to a card
    public func cardHoverState(isActive: Bool, anyCardSelected: Bool) -> some View {
        self.modifier(CardHoverModifier(isActive: isActive, anyCardSelected: anyCardSelected))
    }
}
