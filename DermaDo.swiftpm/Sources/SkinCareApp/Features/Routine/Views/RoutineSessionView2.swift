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
    
    @State private var pulseScale: CGFloat = 1.0
    
    init(routine: Routine, productManager: ProductManagerProtocol, progressManager: ProgressManagerProtocol, trackerManager: TrackerManagerProtocol, activeSession: ActiveRoutineSession, voiceManager: VoiceManager) {
        _viewModel = StateObject(wrappedValue: RoutineSessionViewModel(
            routine: routine,
            productManager: productManager,
            progressManager: progressManager,
            trackerManager: trackerManager,
            activeSession: activeSession
        ))
        _avatarViewModel = StateObject(wrappedValue: AvatarViewModel(activeSession: activeSession, voiceManager: voiceManager))
    }
    
    public var body: some View {
        ZStack {
            // MARK: - 1. Void & Glow Background
            backgroundLayer
            
            VStack(spacing: 0) {
                // MARK: - 2. Top Bar (Close & Progress)
                topSection
                
                Spacer()
                
                // MARK: - 3. Middle Section (Avatar & Info)
                middleSection
                
                Spacer()
                
                // MARK: - 4. Bottom Section (Timer & Controls)
                bottomSection
            }
        }
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
    // MARK: - Top Section
    
    private var topSection: some View {
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
                Text("STEP \(viewModel.currentStepIndex + 1) OF \(viewModel.totalSteps)".uppercased())
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
    
    // MARK: - Middle Section
    
    private var middleSection: some View {
        VStack(spacing: DesignSpacing.medium) {
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
            .frame(height: 350)
            
            if !viewModel.sessionComplete {
                VStack(spacing: DesignSpacing.micro) {
                    Text(viewModel.currentStep?.stepType.rawValue.capitalized ?? "Step")
                        .font(DesignTypography.titleUI)
                        .foregroundColor(DesignColors.luminousPearl)
                        .multilineTextAlignment(.center)
                    
                    Text(viewModel.currentProduct?.name ?? "Follow standard instructions.")
                        .font(DesignTypography.bodyUI)
                        .foregroundColor(DesignColors.liquidSilver)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DesignSpacing.large)
            }
        }
    }
    
    // MARK: - Bottom Section
    
    private var bottomSection: some View {
        VStack(spacing: DesignSpacing.medium) {
            if !viewModel.sessionComplete {
                
                // Time Remaining & Animated Timer Bar
                VStack(spacing: DesignSpacing.small) {
                    HStack {
                        Text(timeString(from: viewModel.timeRemaining))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignSpacing.large)
                    
                    // Horizontal Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(DesignColors.voidAsh.opacity(0.5))
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [orbColor, orbColor.opacity(0.7)]),
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: max(0, geo.size.width * timeProgress), height: 6)
                                .animation(.linear(duration: 1.0), value: timeProgress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, DesignSpacing.large)
                }
                
                // Media Controls
                HStack(spacing: DesignSpacing.large) {
                    MicroButton(icon: "backward.fill",
                                color: viewModel.currentStepIndex > 0 ? DesignColors.liquidSilver : DesignColors.voidAsh,
                                action: { viewModel.previousStep() })
                        .disabled(viewModel.currentStepIndex == 0)
                    
                    Button(action: { viewModel.toggleTimer() }) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isTimerActive ? DesignColors.voidAsh : DesignColors.luminousPearl)
                                .frame(width: 64, height: 64)
                                .shadow(color: DesignColors.luminousPearl.opacity(viewModel.isTimerActive ? 0 : 0.25), radius: 12, y: 6)
                            
                            Image(systemName: viewModel.isTimerActive ? "pause.fill" : "play.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.isTimerActive ? DesignColors.luminousPearl : DesignColors.voidObsidian)
                        }
                    }
                    .buttonStyle(TactilePressStyle())
                    
                    MicroButton(icon: "forward.fill",
                                color: DesignColors.luminousPearl,
                                action: { viewModel.nextStep() })
                }
                .padding(.top, DesignSpacing.small)
                .padding(.bottom, DesignSpacing.large)
                
            } else {
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
                // Pulsing supernova
                Circle()
                    .fill(DesignColors.roseGold.opacity(0.3))
                    .frame(width: 160, height: 160)
                    .blur(radius: 50)
                    .scaleEffect(pulseScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)
                
                // Core bloom
                Circle()
                    .fill(DesignColors.luminousPearl)
                    .frame(width: 100, height: 100)
                    .blur(radius: 30)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(DesignColors.voidObsidian)
            }
            .padding(.bottom, DesignSpacing.standard)
            .onAppear { pulseScale = 1.3 }
            
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
    
    private var timeProgress: CGFloat {
        guard let step = viewModel.currentStep,
              let duration = step.durationSeconds,
              duration > 0 else { return 0 }
        
        let progress = CGFloat(viewModel.timeRemaining) / CGFloat(duration)
        return min(max(progress, 0), 1)
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Helper Views & Styles

struct MicroButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(TactilePressStyle())
    }
}

struct TactilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

