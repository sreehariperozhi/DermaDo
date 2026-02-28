import SwiftUI
import AVFoundation

/// ViewModel driving the onboarding flow state, validation, and profile persistence.
@MainActor
final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let userManager: UserManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    
    // MARK: - Published State
    
    @Published var currentPage: Int = 0
    @Published var userName: String = ""
    @Published var selectedSkinType: SkinType? = nil
    @Published var selectedConcerns: Set<SkinConcern> = []
    
    @Published var cameraPermissionGranted: Bool = false
    @Published var notificationPermissionGranted: Bool = false
    @Published var cameraPermissionRequested: Bool = false
    @Published var notificationPermissionRequested: Bool = false
    
    static let totalPages = 5
    
    // MARK: - Init
    
    init(userManager: UserManagerProtocol, notificationManager: NotificationManagerProtocol) {
        self.userManager = userManager
        self.notificationManager = notificationManager
    }
    
    // MARK: - Validation
    
    var canAdvance: Bool {
        switch currentPage {
        case 0: return true                                    // Welcome — always
        case 1: return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty  // Name required
        case 2: return selectedSkinType != nil                 // Skin type required
        case 3: return true                                    // Concerns optional
        case 4: return true                                    // Permissions optional
        default: return false
        }
    }
    
    var isLastPage: Bool {
        currentPage == Self.totalPages - 1
    }
    
    var progressFraction: CGFloat {
        CGFloat(currentPage + 1) / CGFloat(Self.totalPages)
    }
    
    // MARK: - Navigation
    
    func advance() {
        guard canAdvance, currentPage < Self.totalPages - 1 else { return }
        withAnimation(DesignMotion.editorialSpring) {
            currentPage += 1
        }
    }
    
    func goBack() {
        guard currentPage > 0 else { return }
        withAnimation(DesignMotion.editorialSpring) {
            currentPage -= 1
        }
    }
    
    // MARK: - Permissions
    
    func requestCameraPermission() {
        cameraPermissionRequested = true
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionGranted = granted
            }
        }
    }
    
    func requestNotificationPermission() {
        notificationPermissionRequested = true
        notificationManager.requestAuthorization { [weak self] granted in
            DispatchQueue.main.async {
                self?.notificationPermissionGranted = granted
            }
        }
    }
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() {
        let profile = UserProfile(
            name: userName.trimmingCharacters(in: .whitespacesAndNewlines),
            skinType: selectedSkinType ?? .normal,
            skinConcerns: Array(selectedConcerns)
        )
        
        userManager.saveProfile(profile)
    }
}
