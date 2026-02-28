import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Dependencies
    private let settingsManager: SettingsManagerProtocol
    private let backupManager: BackupManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    private let userManager: UserManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Loop Prevention
    private var isSyncing = false

    // MARK: - Published State
    @Published var selectedTheme: AppTheme {
        didSet { updateSettings() }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            updateSettings()
            if notificationsEnabled && !oldValue {
                requestNotificationAuth()
            }
        }
    }

    @Published var morningReminderTime: Date {
        didSet { updateSettings() }
    }

    @Published var eveningReminderTime: Date {
        didSet { updateSettings() }
    }

    @Published var voiceTone: VoiceTone {
        didSet { updateSettings() }
    }

    @Published var voiceSpeed: Double {
        didSet { updateSettings() }
    }

    @Published var exportURL: URL?
    @Published var importError: String?
    @Published var showImportSuccess: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // MARK: - Initialization
    init(
        settingsManager: SettingsManagerProtocol,
        backupManager: BackupManagerProtocol,
        notificationManager: NotificationManagerProtocol,
        userManager: UserManagerProtocol
    ) {
        self.settingsManager = settingsManager
        self.backupManager = backupManager
        self.notificationManager = notificationManager
        self.userManager = userManager

        // Load initial state
        let settings = settingsManager.loadSettings()
        self.selectedTheme = settings.theme
        self.notificationsEnabled = settings.notificationsEnabled
        self.morningReminderTime = settings.morningReminderTime ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        self.eveningReminderTime = settings.eveningReminderTime ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        self.voiceTone = settings.voiceTone
        self.voiceSpeed = settings.voiceSpeed

        // Bind to manager updates
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newSettings in
                self?.sync(with: newSettings)
            }
            .store(in: &cancellables)
    }

    private func sync(with settings: AppSettings) {
        // Prevent update loops: if we are setting properties from outside convert,
        // we should flag it so didSet observers don't trigger saves back.
        isSyncing = true
        defer { isSyncing = false }

        if selectedTheme != settings.theme {
            self.selectedTheme = settings.theme
        }
        if notificationsEnabled != settings.notificationsEnabled {
            self.notificationsEnabled = settings.notificationsEnabled
        }
        if let morning = settings.morningReminderTime, abs(morning.timeIntervalSince(self.morningReminderTime)) > 1 {
            self.morningReminderTime = morning
        }
        if let evening = settings.eveningReminderTime, abs(evening.timeIntervalSince(self.eveningReminderTime)) > 1 {
            self.eveningReminderTime = evening
        }
        if voiceTone != settings.voiceTone {
            self.voiceTone = settings.voiceTone
        }
        if abs(voiceSpeed - settings.voiceSpeed) > 0.01 {
            self.voiceSpeed = settings.voiceSpeed
        }
    }

    // MARK: - Actions

    private func updateSettings() {
        // If this update was triggered by sync(), do not save back.
        guard !isSyncing else { return }

        let currentSettings = settingsManager.loadSettings()
        
        // Preserve original timestamps so equality check works
        // (default init creates new Date() every time)
        let newSettings = AppSettings(
            theme: selectedTheme,
            notificationsEnabled: notificationsEnabled,
            morningReminderTime: morningReminderTime,
            eveningReminderTime: eveningReminderTime,
            voiceTone: voiceTone,
            voiceSpeed: voiceSpeed,
            dataRetentionDays: currentSettings.dataRetentionDays,
            showAchievements: currentSettings.showAchievements,
            defaultRoutineView: currentSettings.defaultRoutineView,
            hapticFeedbackEnabled: currentSettings.hapticFeedbackEnabled,
            createdAt: currentSettings.createdAt, // KEEP ORIGINAL
            updatedAt: Date() // ONLY UPDATE THIS
        )

        // Prevent redundant writes
        // Because we preserved createdAt, this check now works correctly
        if newSettings == currentSettings { return }

        settingsManager.saveSettings(newSettings)
    }

    private func requestNotificationAuth() {
        notificationManager.requestAuthorization { [weak self] granted in
            if !granted {
                DispatchQueue.main.async {
                    self?.notificationsEnabled = false
                }
            }
        }
    }

    func exportData() {
        backupManager.exportData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self?.exportURL = url
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }
        }
    }

    func importData(from url: URL) {
        backupManager.importData(from: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showImportSuccess = true
                    self?.refresh()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                }
            }
        }
    }

    func refresh() {
        let settings = settingsManager.loadSettings()
        sync(with: settings)
    }
}
