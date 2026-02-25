import Foundation

// MARK: - AppSettings
/// Represents app-wide configuration and user preferences.
/// Immutable value type — create a new instance to update.
struct AppSettings: Codable, Equatable {

    // MARK: - Properties

    var theme: AppTheme
    let notificationsEnabled: Bool
    let morningReminderTime: Date?
    let eveningReminderTime: Date?
    let voiceTone: VoiceTone
    let voiceSpeed: Double
    let dataRetentionDays: Int
    let showAchievements: Bool
    let defaultRoutineView: TimeOfDay
    let hapticFeedbackEnabled: Bool
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Initialization

    init(
        theme: AppTheme = .system,
        notificationsEnabled: Bool = true,
        morningReminderTime: Date? = nil,
        eveningReminderTime: Date? = nil,
        voiceTone: VoiceTone = .neutral,
        voiceSpeed: Double = 1.0,
        dataRetentionDays: Int = 365,
        showAchievements: Bool = true,
        defaultRoutineView: TimeOfDay = .morning,
        hapticFeedbackEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.morningReminderTime = morningReminderTime
        self.eveningReminderTime = eveningReminderTime
        self.voiceTone = voiceTone
        self.voiceSpeed = voiceSpeed
        self.dataRetentionDays = dataRetentionDays
        self.showAchievements = showAchievements
        self.defaultRoutineView = defaultRoutineView
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - AppTheme

enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
    case system
}

// MARK: - VoiceTone

enum VoiceTone: String, Codable, CaseIterable {
    case soft
    case neutral
    case energetic
    
    var displayName: String {
        self.rawValue.capitalized
    }
}
