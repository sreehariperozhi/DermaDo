import Foundation
import Combine

// MARK: - HomeViewModel
/// View model for the Home screen. Computes display-ready data using `ObservableObject`.
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Dependencies

    // MARK: - Dependencies

    private(set) var routineManager: RoutineManagerProtocol
    private let trackerManager: TrackerManagerProtocol
    private let settingsManager: SettingsManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var greetingText: String = ""
    @Published var todayRoutine: Routine?
    @Published var todaySteps: [RoutineStep] = []
    @Published var completedEntriesCount: Int = 0
    @Published var streakDays: Int = 0
    @Published var nextReminderText: String?
    @Published var hasRoutine: Bool = false

    // MARK: - Initialization

    init(
        routineManager: RoutineManagerProtocol,
        trackerManager: TrackerManagerProtocol,
        settingsManager: SettingsManagerProtocol
    ) {
        self.routineManager = routineManager
        self.trackerManager = trackerManager
        self.settingsManager = settingsManager
        
        setupBindings()
        refresh() // Initial calculation
    }
    
    private func setupBindings() {
        // Observe Routines
        routineManager.routinesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.computeTodayRoutine() }
            .store(in: &cancellables)
            
        // Observe Tracker Entries
        trackerManager.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.computeStreak() }
            .store(in: &cancellables)
            
        // Observe Settings for Reminders
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.computeNextReminder() }
            .store(in: &cancellables)
            
        // Timer for Greeting/Reminder updates?
        // Ideally we update greeting periodically, but for now just on appear/refresh is fine.
    }

    // MARK: - Refresh

    /// Re-reads all data sources and recomputes display properties.
    func refresh() {
        computeGreeting()
        computeTodayRoutine()
        computeStreak()
        computeNextReminder()
    }

    // MARK: - Greeting

    private func computeGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "Good Morning"
        case 12..<17: timeOfDay = "Good Afternoon"
        case 17..<21: timeOfDay = "Good Evening"
        default:      timeOfDay = "Good Night"
        }
        greetingText = timeOfDay
    }

    // MARK: - Today's Routine

    private func computeTodayRoutine() {
        let allRoutines = routineManager.fetchAllRoutines()

        // Determine current time-of-day and day-of-week
        let hour = Calendar.current.component(.hour, from: Date())
        let currentTimeOfDay: TimeOfDay = hour < 14 ? .morning : .evening
        let currentDay = currentDayOfWeek()

        // 1. Filter for routines enabled & scheduled for TODAY
        let routinesForToday = allRoutines
            .filter { $0.isEnabled }
            .filter { $0.repeatDays.contains(currentDay) }

        // 2. Sort to prioritize:
        //    a. Matches current time of day (or is .both)
        //    b. Created earlier (stable sort)
        let sortedRoutines = routinesForToday.sorted { r1, r2 in
            let r1Matches = (r1.timeOfDay == currentTimeOfDay || r1.timeOfDay == .both)
            let r2Matches = (r2.timeOfDay == currentTimeOfDay || r2.timeOfDay == .both)
            
            if r1Matches && !r2Matches { return true }
            if !r1Matches && r2Matches { return false }
            
            return r1.createdAt < r2.createdAt
        }

        // 3. Pick the first one (best match)
        let matching = sortedRoutines.first

        todayRoutine = matching
        todaySteps = matching?.steps.sorted { $0.order < $1.order } ?? []
        hasRoutine = matching != nil
    }

    // MARK: - Streak

    private func computeStreak() {
        let entries = trackerManager.fetchAllEntries()
        completedEntriesCount = entries.count

        // Calculate consecutive-day streak ending today
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let entryDates: Set<Date> = Set(
            entries.map { calendar.startOfDay(for: $0.date) }
        )

        var streak = 0
        var checkDate = today
        while entryDates.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        streakDays = streak
    }

    // MARK: - Next Reminder

    private func computeNextReminder() {
        let settings = settingsManager.loadSettings()
        guard settings.notificationsEnabled else {
            nextReminderText = nil
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)

        // Determine which reminder is next
        var targetDate: Date?

        if let morningTime = settings.morningReminderTime, hour < calendar.component(.hour, from: morningTime) {
            targetDate = calendar.nextDate(
                after: now,
                matching: calendar.dateComponents([.hour, .minute], from: morningTime),
                matchingPolicy: .nextTime
            )
        } else if let eveningTime = settings.eveningReminderTime {
            targetDate = calendar.nextDate(
                after: now,
                matching: calendar.dateComponents([.hour, .minute], from: eveningTime),
                matchingPolicy: .nextTime
            )
        }

        guard let target = targetDate else {
            nextReminderText = nil
            return
        }

        let diff = calendar.dateComponents([.hour, .minute], from: now, to: target)
        let hours = diff.hour ?? 0
        let minutes = diff.minute ?? 0

        if hours > 0 {
            nextReminderText = "\(hours)h \(minutes)m until next routine"
        } else if minutes > 0 {
            nextReminderText = "\(minutes)m until next routine"
        } else {
            nextReminderText = "Routine time!"
        }
    }

    // MARK: - Helpers

    private func currentDayOfWeek() -> DayOfWeek {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Calendar weekday: 1=Sun, 2=Mon, ..., 7=Sat
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}
