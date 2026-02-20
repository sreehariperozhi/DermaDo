import SwiftUI

/// Luxury Fashion-Tech Shadow system for DermaDo 2.0
public struct DesignShadows {
    
    /// Inner Glow rule: Premium cards have an inner stroke of a white-to-clear gradient mimicking specular highlights.
    public static var innerGlow: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.white.opacity(0.15), Color.clear]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - View Modifiers

public struct AmbientGlowModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.shadow(color: DesignColors.roseGold.opacity(0.15), radius: 32, x: 0, y: 8)
    }
}

public struct DepthShadowModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.shadow(color: Color.black.opacity(0.8), radius: 64, x: 0, y: 24)
    }
}

extension View {
    /// Actionable Rose Gold ambient glow
    public func ambientGlow() -> some View {
        self.modifier(AmbientGlowModifier())
    }
    
    /// Deep dark shadow for floating objects over the void
    public func depthShadow() -> some View {
        self.modifier(DepthShadowModifier())
    }
}
