import UIKit

// MARK: - App Constants
/// Centralized app-wide configuration constants.
enum AppConstants {
    /// Display name shown across the app.
    static let appName = "Derma"

    /// Maximum number of steps allowed in a single routine.
    static let maxStepsPerRoutine = 15

    /// Maximum products in a routine step.
    static let maxProductsPerStep = 5

    /// Default timer duration in seconds if none is set.
    static let defaultStepDuration: Int = 30

    /// Maximum image size (in bytes) for product photos.
    static let maxImageSizeBytes = 5_000_000

    /// Animation durations — used app-wide for consistency.
    enum Animation {
        static let quick: Double = 0.15
        static let normal: Double = 0.25
        static let slow: Double = 0.5
    }
}
