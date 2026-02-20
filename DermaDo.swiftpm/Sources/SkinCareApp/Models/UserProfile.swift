import Foundation

// MARK: - UserProfile
/// Represents the user's personal profile for personalized skincare recommendations.
/// Immutable value type — create a new instance to update.
struct UserProfile: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let name: String
    let dateOfBirth: Date?
    let skinType: SkinType
    let skinConcerns: [SkinConcern]
    let allergies: [String]
    let photoFileName: String?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String = "",
        dateOfBirth: Date? = nil,
        skinType: SkinType = .normal,
        skinConcerns: [SkinConcern] = [],
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
        self.allergies = allergies
        self.photoFileName = photoFileName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - SkinType

enum SkinType: String, Codable, CaseIterable {
    case normal
    case dry
    case oily
    case combination
    case sensitive
}

// MARK: - SkinConcern

enum SkinConcern: String, Codable, CaseIterable {
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
