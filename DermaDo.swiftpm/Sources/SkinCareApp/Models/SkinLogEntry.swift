import Foundation

// MARK: - SkinEntry
/// Represents a daily skin condition log entry with granular tracking metrics.
/// Immutable value type — create a new instance to update.
struct SkinEntry: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let date: Date
    let acneCount: Int
    let oilLevel: Int          // 0–10 scale
    let drynessLevel: Int      // 0–10 scale
    let rednessLevel: Int      // 0–10 scale
    let textureLevel: Int      // 0–10 scale
    let overallScore: Int?     // 0–10 optional self-assessment
    let mood: Mood
    let photoFileName: String?
    let notes: String?
    let completedRoutineIds: [UUID]
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        acneCount: Int = 0,
        oilLevel: Int = 0,
        drynessLevel: Int = 0,
        rednessLevel: Int = 0,
        textureLevel: Int = 0,
        overallScore: Int? = nil,
        mood: Mood = .neutral,
        photoFileName: String? = nil,
        notes: String? = nil,
        completedRoutineIds: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.acneCount = acneCount
        self.oilLevel = oilLevel
        self.drynessLevel = drynessLevel
        self.rednessLevel = rednessLevel
        self.textureLevel = textureLevel
        self.overallScore = overallScore
        self.mood = mood
        self.photoFileName = photoFileName
        self.notes = notes
        self.completedRoutineIds = completedRoutineIds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Mood

enum Mood: String, Codable, CaseIterable {
    case great
    case good
    case neutral
    case stressed
    case tired
    case anxious
    case sad
}
