import SwiftUI

/// Global Routing State Engine for DermaDo 2.0
///
/// This entirely isolates navigation logic from the views themselves. Views simply 
/// call `router.navigate(to:)` or `router.presentSheet(...)` and the root layout responds.
@MainActor
public final class AppRouter: ObservableObject {
    
    /// The currently selected primary tab/feature module.
    @Published public var currentFeature: AppFeature = .home
    
    // MARK: - Navigation Intents
    
    /// Navigates to a specific top-level feature module.
    public func navigate(to feature: AppFeature) {
        withAnimation(DesignMotion.editorialSpring) {
            currentFeature = feature
        }
    }
}
