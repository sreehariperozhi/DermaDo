import Foundation
import Combine

/// Manages daily streak tracking, avatar glow/brightness computation,
/// and encouragement messages. Persists data via `DataManager`.
public final class ProgressManager: ProgressManagerProtocol, ObservableObject {
    
    // MARK: - Dependencies
    
    private let dataManager: DataManagerProtocol
    
    // MARK: - Published State
    
    @Published private(set) var progress: ProgressData = ProgressData() {
        didSet {
            onProgressChanged?(progress)
        }
    }
    
    public var progressPublisher: AnyPublisher<ProgressData, Never> {
        $progress.eraseToAnyPublisher()
    }
    
    // MARK: - Callbacks
    
    var onProgressChanged: ((ProgressData) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(dataManager: DataManagerProtocol) {
        self.dataManager = dataManager
        loadFromDisk()
        validateStreak()
    }
    
    // MARK: - ProgressManagerProtocol
    
    public func recordCompletion() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Guard against duplicate same-day recordings
        if let last = progress.lastCompletionDate,
           calendar.isDate(last, inSameDayAs: today) {
            return
        }
        
        var updated = progress
        updated.totalCompletions += 1
        updated.completionDates.append(today)
        
        // Streak logic
        if let last = updated.lastCompletionDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(last, inSameDayAs: yesterday) {
                // Continuing streak
                updated.currentStreak += 1
            } else if !calendar.isDate(last, inSameDayAs: today) {
                // Streak broken, restart
                updated.currentStreak = 1
            }
        } else {
            // First ever completion
            updated.currentStreak = 1
        }
        
        updated.longestStreak = max(updated.longestStreak, updated.currentStreak)
        updated.lastCompletionDate = today
        
        progress = updated
        saveToDisk()
    }
    
    public func loadProgress() -> ProgressData {
        return progress
    }
    
    /// Maps streak → glow intensity. Full glow at 14-day streak.
    public var glowIntensity: Double {
        return min(1.0, Double(progress.currentStreak) / 14.0)
    }
    
    /// Maps streak → subtle skin brightness boost. Max 30% at 15+ days.
    public var skinBrightnessBoost: Double {
        return min(0.3, Double(progress.currentStreak) * 0.02)
    }
    
    /// Returns a context-aware encouragement message based on streak tier.
    public var encouragementMessage: String {
        let streak = progress.currentStreak
        
        switch streak {
        case 0:
            return "Start your skincare journey today ✨"
        case 1:
            return "Great start! Day 1 is the hardest 💪"
        case 2:
            return "Two days strong! You're building a habit 🌱"
        case 3...6:
            return "Your skin is thanking you — \(streak) days! 🌿"
        case 7:
            return "One full week! Your glow is showing ✨"
        case 8...13:
            return "\(streak)-day streak! Consistency is the secret 💎"
        case 14:
            return "Two weeks of radiance! You're unstoppable 🔥"
        case 15...29:
            return "\(streak) days! Your dedication is legendary 👑"
        case 30...:
            return "\(streak)-day champion! Your skin has never looked better 🏆"
        default:
            return "Keep glowing ✨"
        }
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        if let data = dataManager.load(forKey: DataManager.StorageKey.progress, as: ProgressData.self) {
            self.progress = data
        }
    }
    
    private func saveToDisk() {
        try? dataManager.save(progress, forKey: DataManager.StorageKey.progress)
    }
    
    /// Validates the streak hasn't lapsed since the app was last opened.
    private func validateStreak() {
        guard let lastDate = progress.lastCompletionDate else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // If last completion was before yesterday, the streak is broken
        if lastDate < yesterday && !calendar.isDate(lastDate, inSameDayAs: yesterday) {
            var updated = progress
            updated.currentStreak = 0
            progress = updated
            saveToDisk()
        }
    }
}
