import Foundation

/// Manages gamification logic and persistence.
protocol AchievementManagerProtocol: AnyObject {
    
    /// Returns the current list of achievements.
    func fetchAllAchievements() -> [Achievement]
    
    /// Evaluates skin log entries against achievement rules and updates progress.
    /// - Parameter entries: The full list of skin entries to evaluate.
    /// - Returns: A list of newly unlocked achievements (to show alerts).
    func evaluateAchievements(using entries: [SkinEntry]) -> [Achievement]
    
    /// Resets all achievements (for testing or user reset).
    func resetAchievements()
}
