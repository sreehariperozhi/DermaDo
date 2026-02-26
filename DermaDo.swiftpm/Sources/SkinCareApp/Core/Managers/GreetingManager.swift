import Foundation

/// Clean, testable greeting logic for DermaDo 2.0.
/// Combines time-of-day salutation with the user's name from onboarding.
public struct GreetingManager {
    
    /// Returns a time-based greeting: "Good Morning", "Good Afternoon", or "Good Evening".
    public static func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default:      return "Good Evening"
        }
    }
    
    /// Returns the username saved during onboarding, or `nil` if not set.
    public static func getUsername() -> String? {
        let name = UserDefaults.standard.string(forKey: "userName")
        guard let name, !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        return name.trimmingCharacters(in: .whitespaces)
    }
    
    /// Returns a complete personalised greeting string.
    /// Example: "Good Morning, Sreehari" or "Welcome back" if no name is stored.
    public static func personalizedGreeting() -> String {
        if let username = getUsername() {
            return "\(getGreeting()), \(username)"
        } else {
            return "Welcome back"
        }
    }
}
