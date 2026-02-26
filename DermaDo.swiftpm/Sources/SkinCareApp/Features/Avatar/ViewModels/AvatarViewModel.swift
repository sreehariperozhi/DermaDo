import SwiftUI
import Combine

/// Manages the state and logic for the 2.0 Minimalist Avatar, bridging
/// core managers to visual reactions via the globally shared `ActiveRoutineSession`.
@MainActor
public final class AvatarViewModel: ObservableObject {
    
    @Published public private(set) var state: AvatarState
    
    /// The globally shared active routine session
    private weak var activeSession: ActiveRoutineSession?
    /// The voice manager for speaking steps
    private weak var voiceManager: VoiceManager?
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(initialState: AvatarState = AvatarState(), activeSession: ActiveRoutineSession? = nil, voiceManager: VoiceManager? = nil) {
        self.state = initialState
        self.activeSession = activeSession
        self.voiceManager = voiceManager
        
        setupBindings()
    }
    
    private func setupBindings() {
        guard let activeSession = activeSession else { return }
        
        // Listen to active routine steps
        activeSession.$currentStep
            .removeDuplicates()
            .sink { [weak self] step in
                self?.reactTo(step: step)
            }
            .store(in: &cancellables)
        
        // Listen to overall progress to augment the glow
        activeSession.$progressPercentage
            .sink { [weak self] progress in
                self?.setGlowIntensity(progress)
            }
            .store(in: &cancellables)
            
        // Listen to voice manager speaking state to augment avatar aura
        if let voiceManager = voiceManager {
            voiceManager.$isSpeaking
                .removeDuplicates()
                .sink { [weak self] isSpeaking in
                    self?.setVoiceListening(isSpeaking)
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Configuration Methods
    
    public func updateSkinTone(to color: Color) {
        state.skinTone = color
    }
    
    public func setExpression(_ expression: String) {
        state.expression = expression
    }
    
    public func updateHairStyle(_ style: String) {
        state.hairStyle = style
    }
    
    public func updateOutfit(_ outfit: String) {
        state.outfit = outfit
    }
    
    // MARK: - Reaction Methods
    
    /// Maps a `RoutineStepType` to visual Avatar overlay configurations.
    private func reactTo(step: RoutineStepType) {
        withAnimation(DesignMotion.editorialSpring) {
            switch step {
            case .cleanser:
                state.expression = "avatar_eyes_closed"
                state.activeOverlay = "avatar_overlay_cleanser"
                voiceManager?.speak("Let's gently cleanse your skin. Use soft, circular motions.")
            case .mask:
                state.expression = "avatar_eyes_closed"
                state.activeOverlay = "avatar_overlay_mask"
                voiceManager?.speak("Gently apply your mask. Let it rest and nourish your skin.")
            case .serum:
                state.expression = "avatar_eyes_winking"
                state.activeOverlay = nil
                voiceManager?.speak("Gently press the serum into your skin to help it absorb.")
            case .moisturizing:
                state.expression = "avatar_eyes_open"
                state.activeOverlay = nil
                voiceManager?.speak("A moment to hydrate. Gently massage the moisturizer into your skin.")
            case .sunscreen:
                state.expression = "avatar_eyes_open"
                state.activeOverlay = nil
                voiceManager?.speak("The final layer of protection. Your skin is glowing beautifully today.")
            case .none:
                state.expression = "avatar_eyes_open"
                state.activeOverlay = nil
                voiceManager?.stop()
            }
        }
    }
    
    /// Instantly returns the avatar to a resting state.
    public func resetToIdle() {
        withAnimation(DesignMotion.editorialSpring) {
            state.expression = "avatar_eyes_open"
            state.activeOverlay = nil
            state.isVoiceListening = false
        }
    }
    
    /// Activates the voice listening aura.
    public func setVoiceListening(_ isListening: Bool) {
        withAnimation(DesignMotion.editorialSpring) {
            state.isVoiceListening = isListening
        }
    }
    
    /// Increases the background aura representing daily skincare adherence.
    public func setGlowIntensity(_ intensity: Double) {
        withAnimation(DesignMotion.heroMaterialize) {
            state.glowIntensity = max(0.0, min(1.0, intensity))
        }
    }
    
    /// Sets the skin brightness boost driven by progress tracking.
    public func setSkinBrightness(_ brightness: Double) {
        withAnimation(DesignMotion.heroMaterialize) {
            state.skinBrightness = max(0.0, min(1.0, brightness))
        }
    }
    
    /// Applies progress-driven glow and skin brightness simultaneously.
    public func applyProgress(glowIntensity: Double, skinBrightness: Double) {
        setGlowIntensity(glowIntensity)
        setSkinBrightness(skinBrightness)
    }
}
