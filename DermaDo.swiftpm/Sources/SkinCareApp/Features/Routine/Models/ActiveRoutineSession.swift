import SwiftUI
import Combine

/// Represents a specific type of step in a skincare routine
public enum RoutineStepType: Equatable {
    case none
    case cleanser
    case exfoliate
    case toner
    case serum
    case mask
    case moisturizing
    case sunscreen
    
    static func mapStepType(_ type: StepType) -> RoutineStepType {
        switch type {
        case .cleanse: return .cleanser
        case .exfoliate: return .exfoliate
        case .tone: return .toner
        case .treat, .apply: return .serum
        case .mask: return .mask
        case .moisturize: return .moisturizing
        case .protect: return .sunscreen
        default: return .none
        }
    }
}

/// A globally accessible state representing the currently executing routine.
/// Bridging the gap between Routine Logic and Avatar visual reactions.
@MainActor
public final class ActiveRoutineSession: ObservableObject {
    
    /// The current overarching step type of the active routine session
    @Published public var currentStep: RoutineStepType = .none
    
    /// The overall progress of the routine setup (0.0 to 1.0)
    @Published public var progressPercentage: Double = 0.0
    
    public init() {}
    
    // In actual implementation, we'd have functions here to advance steps
    // or this might be injected/controlled entirely by a `RoutineViewModel`
}
