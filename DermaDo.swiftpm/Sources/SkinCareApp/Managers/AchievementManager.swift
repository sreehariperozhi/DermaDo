import Foundation

// MARK: - AchievementManager
/// Handles achievement tracking, evaluation, and persistence.
@MainActor
final class AchievementManager: AchievementManagerProtocol {
    
    // MARK: - Dependencies
    
    private let dataManager: DataManagerProtocol
    
    // MARK: - Constants
    
    private let storageKey = DataManager.StorageKey.achievements
    
    // MARK: - Initialization
    
    init(dataManager: DataManagerProtocol = DataManager()) {
        self.dataManager = dataManager
        seedDefaults()
    }
    
    // MARK: - Protocol Methods
    
    func fetchAllAchievements() -> [Achievement] {
        return dataManager.loadCollection(forKey: storageKey, as: Achievement.self)
    }
    
    func evaluateAchievements(using entries: [SkinEntry]) -> [Achievement] {
        var achievements = fetchAllAchievements()
        var unlockedNow: [Achievement] = []
        var hasChanges = false
        
        // Calculate Metrics
        let currentStreak = calculateStreak(from: entries)
        let totalRoutines = calculateTotalRoutineCompletions(from: entries)
        
        // Evaluate each achievement
        for (index, achievement) in achievements.enumerated() {
            guard !achievement.isUnlocked else { continue }
            
            var progress = 0
            var didUnlock = false
            
            switch achievement.category {
            case .streak:
                progress = currentStreak
                if progress >= achievement.requirement {
                    didUnlock = true
                }
            case .routineCompletion:
                progress = totalRoutines
                if progress >= achievement.requirement {
                    didUnlock = true
                }
            default:
                break // Add other types (product count etc) later
            }
            
            // Log Update if Changed
            if progress != achievement.currentProgress || didUnlock {
                var updated = achievement
                updated = Achievement(
                    id: achievement.id,
                    key: achievement.key,
                    title: achievement.title,
                    descriptionText: achievement.descriptionText,
                    iconName: achievement.iconName,
                    category: achievement.category,
                    requirement: achievement.requirement,
                    currentProgress: progress,
                    isUnlocked: didUnlock,
                    unlockedAt: didUnlock ? Date() : nil,
                    createdAt: achievement.createdAt,
                    updatedAt: Date()
                )
                achievements[index] = updated
                hasChanges = true
                
                if didUnlock {
                    unlockedNow.append(updated)
                }
            }
        }
        
        if hasChanges {
            try? dataManager.saveCollection(achievements, forKey: storageKey)
        }
        
        return unlockedNow
    }
    
    func resetAchievements() {
        try? dataManager.delete(forKey: storageKey)
        seedDefaults()
    }
    
    // MARK: - Logic Helpers
    
    private func calculateStreak(from entries: [SkinEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        
        // 1. Sort by date descending
        let sortedEntries = entries.sorted { $0.date > $1.date }
        
        // 2. Reduce to unique calendar days
        _ = Set<String>()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dayStrings = sortedEntries.map { formatter.string(from: $0.date) }
        
        // 3. Count consecutive days backwards from today (or most recent entry if very recent?)
        // Streak implies contiguous days ending TODAY or YESTERDAY to be active.
        // If the last entry was 5 days ago, streak is 0.
        // Let's be lenient: streak is consecutives ending at the most recent entry.
        // But for "current streak", gap breaks it.
        
        guard let lastDate = sortedEntries.first?.date else { return 0 }
        
        // Check if last entry is today or yesterday. If older, streak is 0.
        if !calendar.isDateInToday(lastDate) && !calendar.isDateInYesterday(lastDate) {
            return 0
        }
        
        var streak = 0
        var checkDate = lastDate
        
        // Map all entry dates to "yyyy-MM-dd" set for O(1) lookup
        let entryDatesSet = Set(dayStrings)
        
        // Start checking backwards from lastDate
        while true {
            let dateStr = formatter.string(from: checkDate)
            if entryDatesSet.contains(dateStr) {
                streak += 1
                // Move back 1 day
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateTotalRoutineCompletions(from entries: [SkinEntry]) -> Int {
        return entries.reduce(0) { $0 + $1.completedRoutineIds.count }
    }
    
    // MARK: - Seeding
    
    private func seedDefaults() {
        let existing = fetchAllAchievements()
        guard existing.isEmpty else { return }
        
        let defaults: [Achievement] = [
            Achievement(
                key: "streak_7",
                title: "Week Warrior",
                descriptionText: "Log your skin condition for 7 days in a row.",
                iconName: "flame.fill",
                category: .streak,
                requirement: 7
            ),
            Achievement(
                key: "streak_30",
                title: "Consistency King",
                descriptionText: "Maintain a 30-day streak.",
                iconName: "crown.fill",
                category: .streak,
                requirement: 30
            ),
            Achievement(
                key: "routine_100",
                title: "Routine Master",
                descriptionText: "Complete 100 skincare routines.",
                iconName: "checkmark.seal.fill",
                category: .routineCompletion,
                requirement: 100
            )
        ]
        
        try? dataManager.saveCollection(defaults, forKey: storageKey)
    }
}
