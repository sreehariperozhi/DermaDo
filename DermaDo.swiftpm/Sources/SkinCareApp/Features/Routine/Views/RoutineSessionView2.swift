import SwiftUI
import Combine

/// A cinematic, avatar-driven routine session experience.
/// Replaces the timer circle with an immersive 3D-depth view,
/// where progress is shown as a growing skin glow aura around the avatar.
public struct RoutineSessionView2: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var activeSession: ActiveRoutineSession
    @EnvironmentObject private var voiceManager: VoiceManager
    
    @StateObject private var viewModel: RoutineSessionViewModel
    @StateObject private var avatarViewModel: AvatarViewModel
    
    public init(routine: Routine, productManager: ProductManagerProtocol, activeSession: ActiveRoutineSession, voiceManager: VoiceManager) {
        _viewModel = StateObject(wrappedValue: RoutineSessionViewModel(routine: routine, productManager: productManager, activeSession: activeSession))
        _avatarViewModel = StateObject(wrappedValue: AvatarViewModel(activeSession: activeSession, voiceManager: voiceManager))
    }
    
    public var body: some View {
        ZStack {
            // MARK: - 1. Void & Glow Background
            backgroundLayer
            
            VStack {
                // MARK: - 2. Top Bar (Progress & Close)
                topBar
                
                Spacer()
                
                // MARK: - 3. Center Stage (Avatar & Depth Transitions)
                centerStage
                
                Spacer()
                
                // MARK: - 4. Bottom Panel (Controls & Details)
                bottomPanel
            }
        }
        // Force the dark void aesthetic for the immersive session
        .colorScheme(.dark)
        // Cleanup when closing
        .onDisappear {
            viewModel.destroy()
            avatarViewModel.resetToIdle()
            activeSession.currentStep = .none
            activeSession.progressPercentage = 0.0
            voiceManager.stop()
        }
    }
    
    // MARK: - Layers
    
    private var backgroundLayer: some View {
        ZStack {
            DesignColors.voidObsidian.ignoresSafeArea()
            
            // Dynamic thematic orb that shifts based on step
            Circle()
                .fill(orbColor.opacity(0.15))
                .frame(width: 500, height: 500)
                .blur(radius: 120)
                .offset(x: viewModel.isTransitioning ? -100 : 0, y: -200)
                .animation(DesignMotion.editorialSpring, value: orbColor)
                .animation(DesignMotion.editorialSpring, value: viewModel.isTransitioning)
        }
    }
    
    private var topBar: some View {
        HStack {
            // Close Button
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DesignColors.liquidSilver)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Step Indicator
            if !viewModel.sessionComplete {
                Text("STEP \(viewModel.currentStepIndex + 1) / \(viewModel.totalSteps)".uppercased())
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.luminousPearl)
            }
            
            Spacer()
            
            // Layout balancer
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, DesignSpacing.large)
        .padding(.top, DesignSpacing.standard)
    }
    
    private var centerStage: some View {
        ZStack {
            if viewModel.sessionComplete {
                // Completion Supernova
                completionView
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                // Cinematic Step Transition Container
                ZStack {
                    // ID dictates the transition lifecycle
                    if !viewModel.isTransitioning {
                        AvatarRenderView(viewModel: avatarViewModel)
                            .id(viewModel.currentStepIndex)
                            .transition(DesignMotion.depthTransition)
                    }
                }
            }
        }
        .frame(height: 400)
    }
    
    private var bottomPanel: some View {
        VStack(spacing: DesignSpacing.standard) {
            if !viewModel.sessionComplete {
                
                // Step Info & Timer Card
                HStack(spacing: DesignSpacing.standard) {
                    // Context (Product or Step Type)
                    VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                        Text(viewModel.currentProduct?.name ?? viewModel.currentStep?.stepType.rawValue.capitalized ?? "Step")
                            .font(DesignTypography.titleUI)
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        Text(viewModel.currentStep?.instruction.isEmpty == false ? viewModel.currentStep!.instruction : "Follow standard instructions.")
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.liquidSilver)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Elegant Timer
                    VStack(alignment: .trailing, spacing: DesignSpacing.micro) {
                        Text(timeString(from: viewModel.timeRemaining))
                            .font(.system(size: 28, weight: .light, design: .rounded))
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        Text("REMAINING")
                            .font(DesignTypography.microUI)
                            .captionTracking()
                            .foregroundColor(DesignColors.liquidSilver)
                    }
                }
                .padding(DesignSpacing.medium)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous)
                        .stroke(DesignShadows.innerGlow, lineWidth: 1)
                )
                .padding(.horizontal, DesignSpacing.standard)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
                // Controls Pill
                HStack(spacing: DesignSpacing.large) {
                    // Back
                    Button(action: { viewModel.previousStep() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.currentStepIndex > 0 ? DesignColors.liquidSilver : DesignColors.voidAsh)
                    }
                    .disabled(viewModel.currentStepIndex == 0)
                    
                    // Play/Pause
                    Button(action: { viewModel.toggleTimer() }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isTimerActive ? DesignColors.voidAsh : DesignColors.luminousPearl)
                                .frame(width: 64, height: 64)
                                .shadow(color: DesignColors.luminousPearl.opacity(viewModel.isTimerActive ? 0 : 0.2), radius: 10, y: 5)
                            
                            Image(systemName: viewModel.isTimerActive ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.isTimerActive ? DesignColors.luminousPearl : DesignColors.voidObsidian)
                        }
                    }
                    // Next / Skip
                    Button(action: { viewModel.nextStep() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 24))
                            .foregroundColor(DesignColors.luminousPearl)
                    }
                }
                .padding(.vertical, DesignSpacing.standard)
                .padding(.bottom, DesignSpacing.standard)
                
            } else {
                // Done Button
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Text("Finish Routine")
                }
                .primaryButtonStyle()
                .padding(.horizontal, DesignSpacing.large)
                .padding(.bottom, DesignSpacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(DesignMotion.editorialSpring, value: viewModel.sessionComplete)
    }
    
    private var completionView: some View {
        VStack(spacing: DesignSpacing.medium) {
            ZStack {
                // Supernova bloom
                Circle()
                    .fill(DesignColors.luminousPearl)
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(DesignColors.voidObsidian)
            }
            .padding(.bottom, DesignSpacing.standard)
            
            Text("Routine Complete")
                .font(DesignTypography.displayEditorial)
                .foregroundColor(DesignColors.luminousPearl)
            
            Text("Your skin is glowing.")
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.liquidSilver)
        }
    }
    
    // MARK: - Helpers
    
    private var orbColor: Color {
        if viewModel.sessionComplete { return DesignColors.luminousPearl }
        guard let step = viewModel.currentStep else { return DesignColors.liquidSilver }
        
        switch step.stepType {
        case .cleanse: return DesignColors.liquidSilver
        case .tone, .moisturize: return DesignColors.ceruleanHydration
        case .treat, .mask: return DesignColors.sageBotanical
        case .protect: return DesignColors.roseGold
        default: return DesignColors.voidAsh
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
