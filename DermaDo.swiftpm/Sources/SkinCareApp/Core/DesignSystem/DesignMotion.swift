import SwiftUI

/// Luxury Fashion-Tech Motion Physics for DermaDo 2.0
public enum DesignMotion {
    
    // MARK: - Core Physics Profiles
    
    /// The universal high-friction, dense spring. Use for all structural movements.
    public static let editorialSpring = Animation.spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.2)
    
    /// Snappier physics for micro-interactions (e.g., button press down).
    public static let tactilePress = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Dramatic, slow physics for massive hero items (e.g., initial Avatar load).
    public static let heroMaterialize = Animation.spring(response: 1.2, dampingFraction: 0.85)
    
    /// Fast exit animation for intentional dismissals.
    public static let evaporation = Animation.easeOut(duration: 0.3)
    
    
    // MARK: - Transitions
    
    /// An AnyTransition that gracefully rises and scales in from the void.
    public static var editorialReveal: AnyTransition {
        AnyTransition.asymmetric(
            insertion: AnyTransition.scale(scale: 0.95).combined(with: .opacity).combined(with: .offset(y: 20)),
            removal: AnyTransition.scale(scale: 0.9).combined(with: .opacity)
        )
    }
    
    /// A deep Z-Axis transition for page routing. 
    public static var depthTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .scale(scale: 1.1).combined(with: .opacity),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )
    }
}
