import Foundation
import Combine

/// The 2.0 Home Dashboard ViewModel — connects to real managers
/// and computes display-ready data for the luxury home screen.
@MainActor
public final class HomeDashboardViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let routineManager: RoutineManagerProtocol
    private let trackerManager: TrackerManagerProtocol
    private let settingsManager: SettingsManagerProtocol
    private let progressManager: ProgressManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    
    /// Dynamic greeting based on time of day
    @Published public var greetingText: String = ""
    
    /// The best-match routine for right now
    @Published public var nextRoutineName: String = "No Routine"
    @Published public var nextRoutineTimeDesc: String = ""
    @Published public var nextRoutineStepCount: Int = 0
    @Published public var hasRoutine: Bool = false
    @Published var todayRoutine: Routine?
    
    /// Skin tracker glance
    @Published public var lastSkinScore: String = "—"
    @Published public var skinTrend: String = "No data yet"
    
    /// Consistency
    @Published public var streakDays: Int = 0
    @Published public var totalEntries: Int = 0
    
    /// Encouragement message from progress tracking
    @Published public var encouragementMessage: String = ""
    
    /// Next reminder
    @Published public var nextReminderText: String?
    
    // MARK: - Initialization
    
    init(
        routineManager: RoutineManagerProtocol,
        trackerManager: TrackerManagerProtocol,
        settingsManager: SettingsManagerProtocol,
        progressManager: ProgressManagerProtocol
    ) {
        self.routineManager = routineManager
        self.trackerManager = trackerManager
        self.settingsManager = settingsManager
        self.progressManager = progressManager
        
        setupBindings()
        refresh()
    }
    
    // MARK: - Reactive Bindings
    
    private func setupBindings() {
        routineManager.routinesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.computeTodayRoutine() }
            .store(in: &cancellables)
        
        trackerManager.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.computeSkinGlance()
                self?.computeStreak()
            }
            .store(in: &cancellables)
        
        settingsManager.settingsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.computeNextReminder() }
            .store(in: &cancellables)
        
        progressManager.progressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.computeEncouragement() }
            .store(in: &cancellables)
    }
    
    // MARK: - Refresh All
    
    public func refresh() {
        computeGreeting()
        computeTodayRoutine()
        computeSkinGlance()
        computeStreak()
        computeNextReminder()
        computeEncouragement()
    }
    
    // MARK: - Start Routine
    
    public func startNextRoutine() {
        // Delegation handled by the view via router navigation
        print("[HomeDashboard] Starting routine: \(nextRoutineName)")
    }
    
    // MARK: - Greeting
    
    private func computeGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  greetingText = "Good Morning"
        case 12..<17: greetingText = "Good Afternoon"
        case 17..<21: greetingText = "Good Evening"
        default:      greetingText = "Good Night"
        }
    }
    
    // MARK: - Today's Routine
    
    private func computeTodayRoutine() {
        let allRoutines = routineManager.fetchAllRoutines()
        
        let hour = Calendar.current.component(.hour, from: Date())
        let currentTimeOfDay: TimeOfDay = hour < 14 ? .morning : .evening
        let currentDay = currentDayOfWeek()
        
        // Filter: enabled + scheduled for today
        let routinesForToday = allRoutines
            .filter { $0.isEnabled }
            .filter { $0.repeatDays.contains(currentDay) }
        
        // Sort: prioritize matching time-of-day (or .both), then by creation date
        let sorted = routinesForToday.sorted { r1, r2 in
            let r1Matches = (r1.timeOfDay == currentTimeOfDay || r1.timeOfDay == .both)
            let r2Matches = (r2.timeOfDay == currentTimeOfDay || r2.timeOfDay == .both)
            
            if r1Matches && !r2Matches { return true }
            if !r1Matches && r2Matches { return false }
            return r1.createdAt < r2.createdAt
        }
        
        if let best = sorted.first {
            todayRoutine = best
            nextRoutineName = best.name.isEmpty ? "Untitled Routine" : best.name
            nextRoutineStepCount = best.steps.count
            hasRoutine = true
            
            // Time description
            switch best.timeOfDay {
            case .morning: nextRoutineTimeDesc = "Morning"
            case .evening: nextRoutineTimeDesc = "Evening"
            case .both:    nextRoutineTimeDesc = "Anytime"
            }
        } else {
            todayRoutine = nil
            nextRoutineName = "No Routine"
            nextRoutineTimeDesc = ""
            nextRoutineStepCount = 0
            hasRoutine = false
        }
    }
    
    // MARK: - Skin Glance
    
    private func computeSkinGlance() {
        let entries = trackerManager.fetchAllEntries()
            .sorted { $0.date > $1.date }
        
        guard let latest = entries.first else {
            lastSkinScore = "—"
            skinTrend = "No data yet"
            return
        }
        
        // Score
        if let score = latest.overallScore {
            lastSkinScore = "\(score)"
        } else {
            // Compute a synthetic score from the metrics (average of inverses, scaled)
            let avgIssue = Double(latest.oilLevel + latest.drynessLevel + latest.rednessLevel) / 3.0
            let syntheticScore = max(0, Int(10.0 - avgIssue))
            lastSkinScore = "\(syntheticScore)"
        }
        
        // Trend: compare to previous entry
        if entries.count >= 2 {
            let previous = entries[1]
            let latestAvg = Double(latest.oilLevel + latest.drynessLevel + latest.rednessLevel) / 3.0
            let prevAvg = Double(previous.oilLevel + previous.drynessLevel + previous.rednessLevel) / 3.0
            let diff = prevAvg - latestAvg // positive = improving
            
            if diff > 1.0 {
                skinTrend = "↑ Improving"
            } else if diff < -1.0 {
                skinTrend = "↓ Needs attention"
            } else {
                skinTrend = "→ Stable"
            }
        } else {
            skinTrend = "First entry logged"
        }
    }
    
    // MARK: - Streak
    
    private func computeStreak() {
        let entries = trackerManager.fetchAllEntries()
        totalEntries = entries.count
        
        // Source streak from ProgressManager for consistency
        let progress = progressManager.loadProgress()
        streakDays = progress.currentStreak
    }
    
    // MARK: - Encouragement
    
    private func computeEncouragement() {
        encouragementMessage = progressManager.encouragementMessage
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
        
        var targetDate: Date?
        
        if let morningTime = settings.morningReminderTime,
           hour < calendar.component(.hour, from: morningTime) {
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
