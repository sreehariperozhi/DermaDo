import Foundation
import Combine

// MARK: - UserManager
/// Manages the user profile state reactively, backed by DataManager for persistence.
@MainActor
final class UserManager: UserManagerProtocol, ObservableObject {
    
    // MARK: - Dependencies
    
    private let dataManager: DataManagerProtocol
    
    // MARK: - Published State
    
    @Published private(set) var userProfile: UserProfile?
    
    var userProfilePublisher: AnyPublisher<UserProfile?, Never> {
        $userProfile.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(dataManager: DataManagerProtocol = DataManager()) {
        self.dataManager = dataManager
        
        loadInitialProfile()
        setupObservations()
    }
    
    private func setupObservations() {
        dataManager.dataChanged
            .filter { $0 == DataManager.StorageKey.userProfile }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadInitialProfile()
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialProfile() {
        self.userProfile = dataManager.load(forKey: DataManager.StorageKey.userProfile, as: UserProfile.self)
    }
    
    // MARK: - UserManagerProtocol
    
    func loadProfile() -> UserProfile? {
        return userProfile
    }
    
    func saveProfile(_ profile: UserProfile) {
        // Update local immediately for reactivity
        self.userProfile = profile
        
        // Persist
        try? dataManager.save(profile, forKey: DataManager.StorageKey.userProfile)
    }
    
    func deleteProfile() {
        self.userProfile = nil
        try? dataManager.delete(forKey: DataManager.StorageKey.userProfile)
    }
}
