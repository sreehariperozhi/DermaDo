import SwiftUI
import Combine

// MARK: - Onboarding Stage

/// The stages of the interactive avatar-driven onboarding flow.
public enum OnboardingStage: Int, CaseIterable {
    case welcome = 0
    case name
    case skinType
    case skinGoal
    case ready
}

// MARK: - OnboardingViewModel

/// Manages the state machine for the cinematic onboarding experience.
/// Collects user profile data progressively and saves it on completion.
@MainActor
public final class OnboardingViewModel: ObservableObject {
    
    // MARK: - Stage State
    @Published public var currentStage: OnboardingStage = .welcome
    @Published public var isTransitioning: Bool = false
    
    // MARK: - User Input
    @Published public var userName: String = ""
    @Published var selectedSkinType: SkinType = .normal
    @Published var selectedSkinGoals: Set<SkinGoal> = []
    
    // MARK: - Completion
    @Published public var isComplete: Bool = false
    
    // MARK: - Skin Type Options
    let skinTypeOptions: [(type: SkinType, label: String, icon: String)] = [
        (.normal,      "Normal",      "drop.circle"),
        (.dry,         "Dry",         "sun.dust"),
        (.oily,        "Oily",        "drop.triangle"),
        (.combination, "Combination", "circle.lefthalf.filled"),
        (.sensitive,   "Sensitive",   "leaf")
    ]
    
    // MARK: - Skin Goal Options
    let skinGoalOptions: [SkinGoal] = SkinGoal.allCases
    
    // MARK: - Camera Zoom per Stage
    
    public var avatarScale: CGFloat {
        switch currentStage {
        case .welcome:  return 1.1
        case .name:     return 0.9
        case .skinType: return 1.0
        case .skinGoal: return 0.85
        case .ready:    return 1.2
        }
    }
    
    public var avatarOffsetY: CGFloat {
        switch currentStage {
        case .welcome:  return -20
        case .name:     return -80
        case .skinType: return -60
        case .skinGoal: return -100
        case .ready:    return -40
        }
    }
    
    // MARK: - Question Text
    
    public var questionText: String {
        switch currentStage {
        case .welcome:  return "Hello.\nI am your DermaDo companion."
        case .name:     return "What should I call you?"
        case .skinType: return "How would you describe your skin?"
        case .skinGoal: return "What’s your main skin goal?"
        case .ready:    return "Your personalized skin journey starts now."
        }
    }
    
    public var canAdvance: Bool {
        switch currentStage {
        case .name: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        case .skinGoal: return !selectedSkinGoals.isEmpty
        default: return true
        }
    }
    
    public var buttonLabel: String {
        switch currentStage {
        case .welcome: return "Get Started"
        case .ready:   return "Enter DermaDo"
        default:       return "Continue"
        }
    }
    
    public var currentStepNumber: Int {
        currentStage.rawValue + 1
    }
    
    public var totalSteps: Int {
        OnboardingStage.allCases.count
    }
    
    // MARK: - Navigation
    
    public func toggleSkinGoal(_ goal: SkinGoal) {
        if selectedSkinGoals.contains(goal) {
            selectedSkinGoals.remove(goal)
        } else {
            selectedSkinGoals.insert(goal)
        }
    }
    
    public func advance() {
        guard canAdvance else { return }
        
        let stages = OnboardingStage.allCases
        guard let currentIndex = stages.firstIndex(of: currentStage),
               currentIndex < stages.count - 1 else {
            // Finished — mark as complete
            withAnimation(DesignMotion.heroMaterialize) {
                isComplete = true
            }
            return
        }
        
        // Cinematic transition: fade out → swap stage → fade in
        withAnimation(DesignMotion.evaporation) {
            isTransitioning = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            self.currentStage = stages[currentIndex + 1]
            
            withAnimation(DesignMotion.heroMaterialize) {
                self.isTransitioning = false
            }
        }
    }
}
