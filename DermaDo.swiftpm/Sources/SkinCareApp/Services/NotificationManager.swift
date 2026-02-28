import UserNotifications
import UIKit

// MARK: - NotificationManager
/// Concrete implementation of NotificationManagerProtocol using UNUserNotificationCenter.
@MainActor
final class NotificationManager: NSObject, NotificationManagerProtocol, ObservableObject {
    
    // MARK: - Properties
    
    private let center = UNUserNotificationCenter.current()
    
    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        center.delegate = self
        updatePermissionStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self?.updatePermissionStatus()
                completion(granted)
            }
        }
    }
    
    func checkAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        center.getNotificationSettings { [weak self] settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                self?.permissionStatus = status
                completion(status == .authorized)
            }
        }
    }
    
    private func updatePermissionStatus() {
        center.getNotificationSettings { [weak self] settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                self?.permissionStatus = status
            }
        }
    }
    
    // MARK: - Routines
    
    func scheduleRoutineReminder(_ routine: Routine, at effectiveTime: Date) {
        // First cancel any existing to avoid duplicates
        cancelRoutineReminder(routine)
        
        guard routine.isEnabled, routine.notifyReminder, !routine.repeatDays.isEmpty else { return }
        
        // Resolve components
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: effectiveTime)
        let minute = calendar.component(.minute, from: effectiveTime)
        
        // Schedule a separate notification for each repeat day
        for day in routine.repeatDays {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            components.weekday = weekdayInt(for: day) // 1=Sun, 2=Mon...
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            let content = UNMutableNotificationContent()
            content.title = "Time for your \(routine.name)!"
            content.body = "Keep up the glow ✨ — tap to start your routine."
            content.sound = .default
            
            // ID format: routine_<UUID>_<day>
            let identifier = "routine_\(routine.id.uuidString)_\(day.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling routine \(routine.name): \(error)")
                }
            }
        }
    }
    
    func cancelRoutineReminder(_ routine: Routine) {
        // We need to match all possible day identifiers
        let identifiers = DayOfWeek.allCases.map { "routine_\(routine.id.uuidString)_\($0.rawValue)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Expiry
    
    func scheduleExpiryReminder(_ product: Product) {
        let identifier = "expiry_\(product.id.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        guard let expiryDate = product.expiryDate, !product.isExpired else { return }
        
        // Remind 7 days before
        guard let reminderDate = Calendar.current.date(byAdding: .day, value: -7, to: expiryDate),
              reminderDate > Date() else { return }
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "Product Expiring Soon"
        content.body = "\(product.name) expires in 7 days. Time to restock?"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
    
    func cancelProductExpiry(_ product: Product) { // Helper if needed
         let identifier = "expiry_\(product.id.uuidString)"
         center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Streak
    
    func scheduleStreakWarning(at time: Date) {
        let identifier = "streak_warning"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Don't break your streak!"
        content.body = "Log your skin condition today to keep your streak alive."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
    
    func cancelStreakWarning() {
        // In this simple implementation, "cancel" might just mean "remove pending for today"? 
        // But if it's repeating daily, removing it removes it forever.
        // Strategy: The requirement says "Streak Warning Reminder". Ideally this fires every day.
        // If the user logs today, we basically just want to suppress *today's* instance?
        // UNUserNotificationCenter doesn't easily support "skip next".
        // Alternative: Just let it fire. "Log your skin condition" is valid even if already logged?
        // Or: TrackerManager calls `scheduleStreakWarning` only if not logged?
        // But local notifications need to be scheduled ahead.
        // Let's stick to a simple daily reminder for now. The user can effectively "cancel" it by turning off the setting.
        center.removePendingNotificationRequests(withIdentifiers: ["streak_warning"])
    }
    
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Helpers
    
    private func weekdayInt(for day: DayOfWeek) -> Int {
        switch day {
        case .sunday:    return 1
        case .monday:    return 2
        case .tuesday:   return 3
        case .wednesday: return 4
        case .thursday:  return 5
        case .friday:    return 6
        case .saturday:  return 7
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even if app is foreground
        completionHandler([.banner, .sound])
    }
}
