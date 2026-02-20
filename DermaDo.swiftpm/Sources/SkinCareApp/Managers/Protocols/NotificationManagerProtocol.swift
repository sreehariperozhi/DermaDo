import Foundation
import UserNotifications

// MARK: - NotificationManagerProtocol
/// Manages scheduling and cancelling of local notifications.
protocol NotificationManagerProtocol: AnyObject {
    
    /// Request user permission for notifications.
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    
    /// Check current permission status.
    func checkAuthorization(completion: @escaping (Bool) -> Void)
    
    /// Current authorization status
    var permissionStatus: UNAuthorizationStatus { get }
    
    /// Schedule reminders for a specific routine.
    /// - Parameters:
    ///   - routine: The routine to remind about.
    ///   - effectiveTime: The specific time to fire (resolved from routine or settings).
    func scheduleRoutineReminder(_ routine: Routine, at effectiveTime: Date)
    
    /// Cancel reminders for a specific routine.
    func cancelRoutineReminder(_ routine: Routine)
    
    /// Schedule expiry reminder for a product (e.g. 7 days before).
    func scheduleExpiryReminder(_ product: Product)
    
    /// Cancel expiry reminder for a product.
    func cancelProductExpiry(_ product: Product)
    
    /// Schedule daily streak warning (e.g. "You haven't logged today").
    /// - Parameter time: The time to fire the warning (e.g. 9 PM).
    func scheduleStreakWarning(at time: Date)
    
    /// Cancel any pending streak warning (e.g. after logging an entry).
    func cancelStreakWarning()
    
    /// Remove all pending notifications (useful for "Reset" or logout).
    func removeAllPendingNotifications()
}
