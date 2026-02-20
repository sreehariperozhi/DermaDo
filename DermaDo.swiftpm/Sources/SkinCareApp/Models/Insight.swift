import Foundation

// MARK: - Insight
/// Represents a skincare insight or recommendation derived from user data.
/// Immutable value type — create a new instance to update.
struct Insight: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let title: String
    let body: String
    let category: InsightCategory
    let priority: InsightPriority
    let isRead: Bool
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        category: InsightCategory = .general,
        priority: InsightPriority = .low,
        isRead: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.category = category
        self.priority = priority
        self.isRead = isRead
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - InsightCategory

enum InsightCategory: String, Codable, CaseIterable {
    case general
    case productRecommendation
    case routineOptimization
    case skinTrend
    case expiryWarning
}

// MARK: - InsightPriority

enum InsightPriority: String, Codable, CaseIterable {
    case low
    case medium
    case high
}
