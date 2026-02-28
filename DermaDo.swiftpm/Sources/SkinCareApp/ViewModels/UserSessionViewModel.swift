import SwiftUI
import Combine

/// A global ViewModel that holds the current user's profile state.
/// This acts as a single source of truth for UI components that need to read or update user data,
/// eliminating the need for scattered `@AppStorage` or direct `UserManager` calls in Views.
@MainActor
final class UserSessionViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let userManager: UserManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false
    
    // MARK: - Published State
    @Published var profile: UserProfile?
    
    // Editable properties bound to UI
    @Published var userName: String = "" {
        didSet { updateProfile() }
    }
    @Published var skinType: SkinType = .normal {
        didSet { updateProfile() }
    }
    @Published var skinConcerns: Set<SkinConcern> = [] {
        didSet { updateProfile() }
    }
    @Published var skinGoals: Set<SkinGoal> = [] {
        didSet { updateProfile() }
    }
    
    // MARK: - Init
    
    init(userManager: UserManagerProtocol) {
        self.userManager = userManager
        
        // Load initial state
        if let initialProfile = userManager.loadProfile() {
            syncState(with: initialProfile)
        }
        
        // Listen to updates from the manager
        self.userManager.userProfilePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedProfile in
                guard let profile = updatedProfile else { return }
                self?.syncState(with: profile)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Accessors
    
    var hasCompletedOnboarding: Bool {
        profile != nil
    }
    
    // MARK: - Mutators
    
    private func syncState(with profile: UserProfile) {
        isSyncing = true
        defer { isSyncing = false }
        
        self.profile = profile
        
        if self.userName != profile.name {
            self.userName = profile.name
        }
        if self.skinType != profile.skinType {
            self.skinType = profile.skinType
        }
        if self.skinConcerns != Set(profile.skinConcerns) {
            self.skinConcerns = Set(profile.skinConcerns)
        }
        if self.skinGoals != Set(profile.skinGoals) {
            self.skinGoals = Set(profile.skinGoals)
        }
    }
    
    private func updateProfile() {
        guard !isSyncing else { return }
        
        let newProfile = UserProfile(
            name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            skinType: skinType,
            skinConcerns: Array(skinConcerns),
            skinGoals: Array(skinGoals)
        )
        userManager.saveProfile(newProfile)
    }
    
    func toggleSkinGoal(_ goal: SkinGoal) {
        if skinGoals.contains(goal) {
            skinGoals.remove(goal)
        } else {
            skinGoals.insert(goal)
        }
    }
    
    func toggleSkinConcern(_ concern: SkinConcern) {
        if skinConcerns.contains(concern) {
            skinConcerns.remove(concern)
        } else {
            skinConcerns.insert(concern)
        }
    }
}
