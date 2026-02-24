import Foundation
import Combine

/// Protocol defining the progress tracking interface.
public protocol ProgressManagerProtocol: AnyObject {
    
    /// Records a routine completion for today, updating streak and stats.
    func recordCompletion()
    
    /// Returns the current progress data.
    func loadProgress() -> ProgressData
    
    /// Avatar glow intensity (0.0–1.0) derived from current streak.
    var glowIntensity: Double { get }
    
    /// Subtle skin brightness boost (0.0–1.0) derived from current streak.
    var skinBrightnessBoost: Double { get }
    
    /// Context-aware encouragement message based on streak length.
    var encouragementMessage: String { get }
    
    /// Reactive publisher for progress changes.
    var progressPublisher: AnyPublisher<ProgressData, Never> { get }
}
