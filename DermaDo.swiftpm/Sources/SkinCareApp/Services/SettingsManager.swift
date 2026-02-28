import Foundation
import Combine

// MARK: - SettingsManager
/// Manages app settings using DataManager for persistence.
@MainActor
final class SettingsManager: SettingsManagerProtocol, ObservableObject {

    // MARK: - Dependencies

    private let dataManager: DataManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    
    // MARK: - Published State
    
    @Published private(set) var settings: AppSettings = AppSettings() {
        didSet {
            onSettingsChanged?(settings)
        }
    }
    
    var settingsPublisher: AnyPublisher<AppSettings, Never> {
        $settings.eraseToAnyPublisher()
    }
    
    // MARK: - Callbacks
    
    var onSettingsChanged: ((AppSettings) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        dataManager: DataManagerProtocol = DataManager(),
        notificationManager: NotificationManagerProtocol
    ) {
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        
        loadInitialSettings()
        setupDetailedObservations()
    }
    
    private func setupDetailedObservations() {
        dataManager.dataChanged
            .filter { $0 == DataManager.StorageKey.settings }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadInitialSettings()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialSettings() {
        if let stored = dataManager.load(forKey: DataManager.StorageKey.settings, as: AppSettings.self) {
            self.settings = stored
        } else {
            self.settings = AppSettings()
        }
    }

    // MARK: - SettingsManagerProtocol

    func loadSettings() -> AppSettings {
        return settings
    }

    func saveSettings(_ newSettings: AppSettings) {
        // Prevent redundant writes if identical
        guard newSettings != settings else { return }

        // Update local immediately
        self.settings = newSettings
        
        // Persist
        try? dataManager.save(newSettings, forKey: DataManager.StorageKey.settings)
        
        // Handle Streak Warning
        if newSettings.notificationsEnabled {
            let time = newSettings.eveningReminderTime ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
            notificationManager.scheduleStreakWarning(at: time)
        } else {
            notificationManager.cancelStreakWarning()
            notificationManager.removeAllPendingNotifications()
        }
    }

    func updateTheme(_ theme: AppTheme) {
        var current = settings
        current.theme = theme
        saveSettings(current)
    }
    
    func resetToDefaults() {
        let defaults = AppSettings()
        saveSettings(defaults)
    }
}
