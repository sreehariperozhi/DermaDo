import SwiftUI

/// A modifier that delays the appearance of an element so it can gracefully animate in.
/// Used for staggering lists or hero content.
public struct EntryTransitionModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    public init(delay: Double = 0.0) {
        self.delay = delay
    }
    
    public func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .animation(
                DesignMotion.editorialSpring.delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

// Convenience extension
extension View {
    /// Applies the DermaDo 2.0 Editorial Reveal entry animation
    public func editorialReveal(delay: Double = 0.0) -> some View {
        self.modifier(EntryTransitionModifier(delay: delay))
    }
}
