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
    let poreLevel: Int         // 0–10 scale
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
        poreLevel: Int = 0,
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
        self.poreLevel = poreLevel
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

// MARK: - Mood Extensions

extension Mood {
    /// SF Symbol name for each mood.
    var sfSymbol: String {
        switch self {
        case .great:    return "face.smiling"
        case .good:     return "hand.thumbsup"
        case .neutral:  return "minus.circle"
        case .stressed: return "cloud.bolt"
        case .tired:    return "moon.zzz"
        case .anxious:  return "exclamationmark.triangle"
        case .sad:      return "drop"
        }
    }

    /// Display name for the mood.
    var displayName: String {
        switch self {
        case .great:    return "Great"
        case .good:     return "Good"
        case .neutral:  return "Neutral"
        case .stressed: return "Stressed"
        case .tired:    return "Tired"
        case .anxious:  return "Anxious"
        case .sad:      return "Sad"
        }
    }
}
