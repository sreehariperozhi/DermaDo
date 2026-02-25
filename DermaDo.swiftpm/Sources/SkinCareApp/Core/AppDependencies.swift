import Foundation

/// Container for all long-lived app dependencies.
final class AppDependencies: ObservableObject {
    
    // MARK: - Core Managers
    
    let dataManager: DataManager
    let notificationManager: NotificationManagerProtocol
    let achievementManager: AchievementManagerProtocol
    let backupManager: BackupManagerProtocol
    
    // MARK: - Domain Managers
    
    let routineManager: RoutineManagerProtocol
    let productManager: ProductManagerProtocol
    let trackerManager: TrackerManagerProtocol
    let settingsManager: SettingsManagerProtocol
    let progressManager: ProgressManagerProtocol
    
    // MARK: - Initialization
    
    init() {
        // 1. Core Data & Notifications
        let dataManager = DataManager()
        self.dataManager = dataManager
        
        // 2. Notifications
        let notificationManager = NotificationManager()
        self.notificationManager = notificationManager
        
        // 3. Independent Domain Managers
        // Removed InsightManager
        
        // 4. Achievement Manager (depends on Data)
        let achievementManager = AchievementManager(dataManager: dataManager)
        self.achievementManager = achievementManager
        
        // 5. Settings Manager (depends on Data, Notifications)
        let settingsManager = SettingsManager(dataManager: dataManager, notificationManager: notificationManager)
        self.settingsManager = settingsManager
        
        // 6. Routine Manager (depends on Data, Notifications, Settings)
        let routineManager = RoutineManager(
            dataManager: dataManager,
            notificationManager: notificationManager,
            settingsManager: settingsManager
        )
        self.routineManager = routineManager
        
        // 7. Product Manager (depends on Data, Notifications)
        self.productManager = ProductManager(
            dataManager: dataManager,
            notificationManager: notificationManager
        )
        
        // 8. Tracker Manager (depends on Data)
        let trackerManager = TrackerManager(dataManager: dataManager)
        self.trackerManager = trackerManager
        
        // 9. Progress Manager (depends on Data)
        self.progressManager = ProgressManager(dataManager: dataManager)
        
        // 9. Backup Manager (depends on everything)
        self.backupManager = BackupManager(
            dataManager: dataManager,
            routineManager: routineManager,
            productManager: productManager,
            trackerManager: trackerManager,
            achievementManager: achievementManager,
            settingsManager: settingsManager
        )
        
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        // Settings changed -> Reschedule reminders
        (settingsManager as? SettingsManager)?.onSettingsChanged = { [weak self] _ in
            self?.routineManager.rescheduleAllReminders()
        }
        
        // Entries changed -> Evaluate achievements
        (trackerManager as? TrackerManager)?.onEntriesChanged = { [weak self] entries in
            // Note: In SwiftUI we might handle this differently (e.g. observing Published properties),
            // but preserving the callback logic here ensures functionality remains.
            // We'll expose unlocked achievements via a Published property in a ViewModel if needed.
             _ = self?.achievementManager.evaluateAchievements(using: entries)
        }
    }
}
