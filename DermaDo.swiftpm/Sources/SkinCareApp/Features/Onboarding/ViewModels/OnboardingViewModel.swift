import SwiftUI
import Combine

// MARK: - Onboarding Stage

/// The stages of the interactive avatar-driven onboarding flow.
public enum OnboardingStage: Int, CaseIterable {
    case welcome = 0
    case name
    case skinTone
    case skinType
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
    @Published public var selectedSkinTone: Color = DesignColors.sandalwoodMedium
    @Published var selectedSkinType: SkinType = .normal
    
    // MARK: - Completion
    @Published public var isComplete: Bool = false
    
    // MARK: - Available Skin Tones
    public let skinToneOptions: [(name: String, color: Color)] = [
        ("Fair",        Color(hex: "#FFE0BD")),
        ("Light",       Color(hex: "#FFDAC1")),
        ("Medium",      DesignColors.sandalwoodMedium),
        ("Olive",       Color(hex: "#E0AC69")),
        ("Tan",         Color(hex: "#C68642")),
        ("Deep",        Color(hex: "#8D5524"))
    ]
    
    // MARK: - Skin Type Options
    let skinTypeOptions: [(type: SkinType, label: String, icon: String)] = [
        (.normal,      "Normal",      "drop.circle"),
        (.dry,         "Dry",         "sun.dust"),
        (.oily,        "Oily",        "drop.triangle"),
        (.combination, "Combination", "circle.lefthalf.filled"),
        (.sensitive,   "Sensitive",   "leaf")
    ]
    
    // MARK: - Camera Zoom per Stage
    
    public var avatarScale: CGFloat {
        switch currentStage {
        case .welcome:  return 1.2
        case .name:     return 1.0
        case .skinTone: return 1.8
        case .skinType: return 1.0
        case .ready:    return 1.3
        }
    }
    
    public var avatarOffsetY: CGFloat {
        switch currentStage {
        case .welcome:  return 20
        case .name:     return -50
        case .skinTone: return 100
        case .skinType: return -50
        case .ready:    return 0
        }
    }
    
    // MARK: - Question Text
    
    public var questionText: String {
        switch currentStage {
        case .welcome:  return "Hello.\nI'm your DermaDo companion."
        case .name:     return "What should I call you?"
        case .skinTone: return "Let's personalize\nmy look."
        case .skinType: return "How would you describe\nyour skin?"
        case .ready:    return "Perfect.\nLet's get glowing."
        }
    }
    
    public var canAdvance: Bool {
        switch currentStage {
        case .name: return !userName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }
    
    public var buttonLabel: String {
        switch currentStage {
        case .welcome: return "Begin"
        case .ready:   return "Enter DermaDo"
        default:       return "Continue"
        }
    }
    
    // MARK: - Navigation
    
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
