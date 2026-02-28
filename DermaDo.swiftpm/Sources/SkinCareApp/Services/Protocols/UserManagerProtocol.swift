import Combine

// MARK: - UserManagerProtocol
/// Defines the contract for managing user profile state reactively.
@MainActor
protocol UserManagerProtocol: AnyObject {
    var userProfilePublisher: AnyPublisher<UserProfile?, Never> { get }
    
    func loadProfile() -> UserProfile?
    func saveProfile(_ profile: UserProfile)
    func deleteProfile()
}
