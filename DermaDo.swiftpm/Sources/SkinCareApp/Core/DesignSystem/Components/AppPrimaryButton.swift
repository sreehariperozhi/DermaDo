import SwiftUI

/// Luxury Fashion-Tech Primary Action Button
public struct PrimaryButtonStyle: ButtonStyle {
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignTypography.titleUI)
            .foregroundColor(DesignColors.voidObsidian) // Dark text on light button
            .padding(.vertical, DesignSpacing.standard)
            .padding(.horizontal, DesignSpacing.large)
            .frame(maxWidth: .infinity)
            .background(DesignColors.roseGold)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous))
            // Button States: Scale down and dim when pressed
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: configuration.isPressed)
            .ambientGlow()
    }
}

// Convenience extension
extension View {
    /// Applies the DermaDo 2.0 Primary Button Style
    public func primaryButtonStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
}
