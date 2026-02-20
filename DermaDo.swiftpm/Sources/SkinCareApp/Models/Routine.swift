import Foundation

// MARK: - Routine
/// Represents a skincare routine with ordered steps, repeat schedule, and enable/disable.
struct Routine: Codable, Identifiable, Equatable {

    // MARK: - Properties

    let id: UUID
    let name: String
    let timeOfDay: TimeOfDay
    let steps: [RoutineStep]
    let repeatDays: [DayOfWeek]
    var isEnabled: Bool
    let notifyReminder: Bool
    let reminderTime: Date?
    let createdAt: Date
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        name: String = "",
        timeOfDay: TimeOfDay = .morning,
        steps: [RoutineStep] = [],
        repeatDays: [DayOfWeek] = DayOfWeek.allCases,
        isEnabled: Bool = true,
        notifyReminder: Bool = false,
        reminderTime: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.timeOfDay = timeOfDay
        self.steps = steps
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.notifyReminder = notifyReminder
        self.reminderTime = reminderTime
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - RoutineStep
/// A single ordered step within a routine, optionally linked to a product.
struct RoutineStep: Codable, Identifiable, Equatable {

    let id: UUID
    var order: Int
    var productId: UUID?
    var stepType: StepType
    var instruction: String
    var durationSeconds: Int?
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        order: Int = 0,
        productId: UUID? = nil,
        stepType: StepType = .apply,
        instruction: String = "",
        durationSeconds: Int? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.order = order
        self.productId = productId
        self.stepType = stepType
        self.instruction = instruction
        self.durationSeconds = durationSeconds
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Supporting Enums

enum TimeOfDay: String, Codable, CaseIterable {
    case morning
    case evening
    case both
}

enum DayOfWeek: String, Codable, CaseIterable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

enum StepType: String, Codable, CaseIterable {
    case cleanse
    case tone
    case treat
    case moisturize
    case protect
    case exfoliate
    case mask
    case apply
    case wait
}
