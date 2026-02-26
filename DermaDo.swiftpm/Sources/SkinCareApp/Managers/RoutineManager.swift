import Foundation
import Combine

// MARK: - RoutineManager
/// Manages skincare routines using DataManager for persistence.
@MainActor
final class RoutineManager: RoutineManagerProtocol, ObservableObject {

    // MARK: - Dependencies

    private let dataManager: DataManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    private let settingsManager: SettingsManagerProtocol
    
    // MARK: - Published State
    
    @Published private(set) var routines: [Routine] = []
    
    var routinesPublisher: AnyPublisher<[Routine], Never> {
        $routines.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        dataManager: DataManagerProtocol = DataManager(),
        notificationManager: NotificationManagerProtocol,
        settingsManager: SettingsManagerProtocol
    ) {
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        self.settingsManager = settingsManager
        
        loadRoutines()
        setupDetailedObservations()
    }
    
    private func setupDetailedObservations() {
        dataManager.dataChanged
            .filter { $0 == DataManager.StorageKey.routines }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadRoutines()
            }
            .store(in: &cancellables)
    }
    
    private func loadRoutines() {
        self.routines = dataManager.loadCollection(forKey: DataManager.StorageKey.routines, as: Routine.self)
    }

    // MARK: - RoutineManagerProtocol

    func fetchAllRoutines() -> [Routine] {
        return routines
    }

    func fetchRoutine(byId id: UUID) -> Routine? {
        return routines.first { $0.id == id }
    }

    func saveRoutine(_ routine: Routine) {
        var currentRoutines = routines
        if let index = currentRoutines.firstIndex(where: { $0.id == routine.id }) {
            currentRoutines[index] = routine
        } else {
            currentRoutines.append(routine)
        }
        
        // Optimistic update
        self.routines = currentRoutines
        
        // Persist
        try? dataManager.saveCollection(currentRoutines, forKey: DataManager.StorageKey.routines)
        
        // Schedule Notification
        scheduleNotification(for: routine)
    }

    func deleteRoutine(byId id: UUID) {
        guard let routine = routines.first(where: { $0.id == id }) else { return }
        
        var currentRoutines = routines
        currentRoutines.removeAll { $0.id == id }
        
        // Optimistic update
        self.routines = currentRoutines
        
        // Persist
        try? dataManager.saveCollection(currentRoutines, forKey: DataManager.StorageKey.routines)
        notificationManager.cancelRoutineReminder(routine)
    }

    func rescheduleAllReminders() {
        let currentRoutines = routines
        for routine in currentRoutines {
            scheduleNotification(for: routine)
        }
    }
    
    // MARK: - Helpers
    
    private func scheduleNotification(for routine: Routine) {
        // Calculate effective time
        let effectiveTime: Date
        if let time = routine.reminderTime {
            effectiveTime = time
        } else {
            let settings = settingsManager.loadSettings()
            if routine.timeOfDay == .evening {
                effectiveTime = settings.eveningReminderTime ?? Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
            } else {
                effectiveTime = settings.morningReminderTime ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
            }
        }
        notificationManager.scheduleRoutineReminder(routine, at: effectiveTime)
    }
}
