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
    private let userManager: UserManagerProtocol
    
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
    
    public enum TrendStatus {
        case improving, stable, declining, unknown
        
        public var icon: String {
            switch self {
            case .improving: return "arrow.up"
            case .stable: return "arrow.right"
            case .declining: return "arrow.down"
            case .unknown: return "minus"
            }
        }
        
        public var label: String {
            switch self {
            case .improving: return "Improving"
            case .stable: return "Stable"
            case .declining: return "Declining"
            case .unknown: return "No data"
            }
        }
    }
    
    /// Skin tracker glance
    @Published public var lastSkinScore: String = "—"
    @Published public var skinTrendStatus: TrendStatus = .unknown
    @Published public var scoreHistory: [Double] = []
    
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
        progressManager: ProgressManagerProtocol,
        userManager: UserManagerProtocol
    ) {
        self.routineManager = routineManager
        self.trackerManager = trackerManager
        self.settingsManager = settingsManager
        self.progressManager = progressManager
        self.userManager = userManager
        
        setupBindings()
        refresh()
    }
    
    // MARK: - Reactive Bindings
    
    private func setupBindings() {
        userManager.userProfilePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.computeGreeting(name: profile?.name)
            }
            .store(in: &cancellables)
        
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
        guard let routine = todayRoutine, routine.isEnabled else { return }
        // Delegation handled by the view via router navigation
        print("[HomeDashboard] Starting routine: \(nextRoutineName)")
    }
    
    public func toggleRoutineEnabled() {
        guard var routine = todayRoutine else { return }
        routine.isEnabled.toggle()
        routine.updatedAt = Date()
        routineManager.saveRoutine(routine)
        refresh()
    }
    
    // MARK: - Greeting
    
    private func computeGreeting(name: String? = nil) {
        greetingText = GreetingManager.personalizedGreeting(name: name)
    }
    
    // MARK: - Today's Routine
    
    private func computeTodayRoutine() {
        let allRoutines = routineManager.fetchAllRoutines()
        
        let hour = Calendar.current.component(.hour, from: Date())
        let currentTimeOfDay: TimeOfDay = hour < 14 ? .morning : .evening
        let currentDay = currentDayOfWeek()
        
        // Filter: scheduled for today (include disabled)
        let routinesForToday = allRoutines
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
            .sorted { $0.date < $1.date } // Chronological for processing
        
        guard let latest = entries.last else {
            lastSkinScore = "—"
            skinTrendStatus = .unknown
            scoreHistory = []
            return
        }
        
        // 1. Current Score
        lastSkinScore = formatScore(computeScore(for: latest))
        
        // 2. 7-Day History (Temporal)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var history: [Double] = []
        
        // We'll look back 6 days + today = 7 days
        for i in (0..<7).reversed() {
            let targetDate = calendar.date(byAdding: .day, value: -i, to: today)!
            
            // Find entries for this day
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: targetDate) }
            
            if !dayEntries.isEmpty {
                let dayAvg = dayEntries.map { computeScore(for: $0) }.reduce(0, +) / Double(dayEntries.count)
                history.append(dayAvg)
            } else {
                // No entry for this day. Use previous day's value if it's not the first point,
                // otherwise find the closest previous entry.
                if let lastVal = history.last {
                    history.append(lastVal)
                } else {
                    // Find most recent entry BEFORE this day
                    let previousEntries = entries.filter { $0.date < targetDate }
                    if let mostRecent = previousEntries.last {
                        history.append(computeScore(for: mostRecent))
                    } else {
                        // Default to 5.0 as a baseline if no history at all.
                        history.append(5.0)
                    }
                }
            }
        }
        
        scoreHistory = history
        
        // 3. Trend: compare latest to previous point in history
        if history.count >= 2 {
            let current = history.last!
            let previous = history[history.count - 2]
            let diff = current - previous
            
            if diff > 0.3 {
                skinTrendStatus = .improving
            } else if diff < -0.3 {
                skinTrendStatus = .declining
            } else {
                skinTrendStatus = .stable
            }
        } else {
            skinTrendStatus = .unknown
        }
    }
    
    private func computeScore(for entry: SkinEntry) -> Double {
        if let score = entry.overallScore {
            return Double(score)
        } else {
            let avgIssue = Double(entry.oilLevel + entry.drynessLevel + entry.rednessLevel) / 3.0
            return max(0.0, 10.0 - avgIssue)
        }
    }
    
    private func formatScore(_ score: Double) -> String {
        if score == floor(score) {
            return "\(Int(score))"
        } else {
            return String(format: "%.1f", score)
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
