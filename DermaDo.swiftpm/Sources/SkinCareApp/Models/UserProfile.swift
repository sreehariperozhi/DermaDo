import Foundation

// MARK: - UserProfile
/// Represents the user's personal profile for personalized skincare recommendations.
/// Immutable value type — create a new instance to update.
public struct UserProfile: Codable, Identifiable, Equatable {

    // MARK: - Properties

    public let id: UUID
    public let name: String
    public let dateOfBirth: Date?
    public let skinType: SkinType
    public let skinConcerns: [SkinConcern]
    public let skinGoals: [SkinGoal]
    public let allergies: [String]
    public let photoFileName: String?
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String = "",
        dateOfBirth: Date? = nil,
        skinType: SkinType = .normal,
        skinConcerns: [SkinConcern] = [],
        skinGoals: [SkinGoal] = [],
        allergies: [String] = [],
        photoFileName: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.skinType = skinType
        self.skinConcerns = skinConcerns
        self.skinGoals = skinGoals
        self.allergies = allergies
        self.photoFileName = photoFileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - SkinType

public enum SkinType: String, Codable, CaseIterable {
    case normal
    case dry
    case oily
    case combination
    case sensitive
}

// MARK: - SkinGoal

public enum SkinGoal: String, Codable, CaseIterable {
    case clearAcne = "Clear Acne"
    case reduceOil = "Reduce Oil"
    case deepHydration = "Deep Hydration"
    case brightening = "Brightening"
    case antiAging = "Anti-aging"
    case evenSkinTone = "Even Skin Tone"
}

// MARK: - SkinConcern

public enum SkinConcern: String, Codable, CaseIterable {
    case acne
    case aging
    case darkSpots
    case dryness
    case dullness
    case largePores
    case redness
    case sensitivity
    case unEvenTexture
    case wrinkles
}
