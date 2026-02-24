import Foundation

/// Persistent model for tracking the user's skincare consistency progress.
/// Stored locally as JSON via `DataManager`.
public struct ProgressData: Codable, Equatable {
    
    /// Current consecutive days with at least one routine completion.
    public var currentStreak: Int
    
    /// All-time longest streak record.
    public var longestStreak: Int
    
    /// The last date a routine was marked complete (start of day).
    public var lastCompletionDate: Date?
    
    /// Lifetime total routine completions.
    public var totalCompletions: Int
    
    /// History of completion dates (start-of-day normalized).
    public var completionDates: [Date]
    
    public init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletionDate: Date? = nil,
        totalCompletions: Int = 0,
        completionDates: [Date] = []
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletionDate = lastCompletionDate
        self.totalCompletions = totalCompletions
        self.completionDates = completionDates
    }
}
