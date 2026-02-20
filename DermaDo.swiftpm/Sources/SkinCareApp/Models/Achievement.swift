import Foundation

// MARK: - Achievement
/// Represents a gamification achievement the user can unlock.
/// Immutable value type — create a new instance to update.
struct Achievement: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let key: String
    let title: String
    let descriptionText: String
    let iconName: String
    let category: AchievementCategory
    let requirement: Int        // e.g., 7 for "7-day streak"
    let currentProgress: Int
    let isUnlocked: Bool
    let unlockedAt: Date?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        key: String = "",
        title: String = "",
        descriptionText: String = "",
        iconName: String = "star",
        category: AchievementCategory = .streak,
        requirement: Int = 1,
        currentProgress: Int = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.title = title
        self.descriptionText = descriptionText
        self.iconName = iconName
        self.category = category
        self.requirement = requirement
        self.currentProgress = currentProgress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Progress as a fraction from 0.0 to 1.0.
    var progressFraction: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement), 1.0)
    }
}

// MARK: - AchievementCategory

enum AchievementCategory: String, Codable, CaseIterable {
    case streak
    case productCount
    case routineCompletion
    case skinImprovement
    case milestone
}
