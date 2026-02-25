import SwiftUI

/// Luxury Fashion-Tech Glassmorphism Modifier
public struct GlassCardModifier: ViewModifier {
    
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .padding(DesignSpacing.standard)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous)
                    .stroke(DesignShadows.innerGlow, lineWidth: 0.5)
            )
    }
}

// Convenience extension
extension View {
    /// Applies the DermaDo 2.0 Glass Panel style
    public func glassCard() -> some View {
        self.modifier(GlassCardModifier())
    }
}
