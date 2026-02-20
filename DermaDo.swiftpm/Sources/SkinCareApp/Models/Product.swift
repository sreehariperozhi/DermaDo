import Foundation

// MARK: - Product
/// Represents a skincare product with full tracking fields.
/// Immutable value type — create a new instance to update.
struct Product: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let name: String
    let brand: String
    let category: ProductCategory
    let size: String?
    let ingredients: [String]
    let openedDate: Date?
    let expiryDate: Date?
    let imageFileName: String?
    let linkedRoutineIds: [UUID]
    let notes: String?
    let rating: Int?
    let isFavorite: Bool
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String = "",
        brand: String = "",
        category: ProductCategory = .other,
        size: String? = nil,
        ingredients: [String] = [],
        openedDate: Date? = nil,
        expiryDate: Date? = nil,
        imageFileName: String? = nil,
        linkedRoutineIds: [UUID] = [],
        notes: String? = nil,
        rating: Int? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.size = size
        self.ingredients = ingredients
        self.openedDate = openedDate
        self.expiryDate = expiryDate
        self.imageFileName = imageFileName
        self.linkedRoutineIds = linkedRoutineIds
        self.notes = notes
        self.rating = rating
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Returns true if the product has expired based on `expiryDate`.
    var isExpired: Bool {
        guard let expiryDate = expiryDate else { return false }
        return Date() > expiryDate
    }
}

// MARK: - ProductCategory

enum ProductCategory: String, Codable, CaseIterable {
    case cleanser
    case toner
    case serum
    case moisturizer
    case sunscreen
    case mask
    case exfoliant
    case eyeCream
    case lipCare
    case bodyLotion
    case other

    var displayName: String {
        switch self {
        case .cleanser:    return "Cleanser"
        case .toner:       return "Toner"
        case .serum:       return "Serum"
        case .moisturizer: return "Moisturizer"
        case .sunscreen:   return "Sunscreen"
        case .mask:        return "Mask"
        case .exfoliant:   return "Exfoliant"
        case .eyeCream:    return "Eye Cream"
        case .lipCare:     return "Lip Care"
        case .bodyLotion:  return "Body Lotion"
        case .other:       return "Other"
        }
    }

    var icon: String {
        switch self {
        case .cleanser:    return "drop.fill"
        case .toner:       return "humidity.fill"
        case .serum:       return "flask.fill"
        case .moisturizer: return "hand.raised.fill"
        case .sunscreen:   return "sun.max.fill"
        case .mask:        return "theatermasks.fill"
        case .exfoliant:   return "sparkles"
        case .eyeCream:    return "eye.fill"
        case .lipCare:     return "mouth.fill"
        case .bodyLotion:  return "figure.stand"
        case .other:       return "ellipsis.circle.fill"
        }
    }
}
