import SwiftUI

/// A cinematic, fashion-tech onboarding experience where the Avatar
/// guides the user through personalizing their skincare profile.
///
/// Layout:
///   - Background: Void obsidian + ambient gradient orb
///   - Middle: AvatarRenderView with dynamic camera zoom per stage
///   - Foreground: Editorial typography + interactive controls
public struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var avatarViewModel = AvatarViewModel()
    
    /// Called by parent when onboarding completes, with the user's chosen data.
    var onComplete: (String, Color, SkinType) -> Void
    
    init(onComplete: @escaping (String, Color, SkinType) -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            // MARK: - Layer 1: Void Background
            backgroundLayer
            
            // MARK: - Layer 2: Avatar with Camera Zoom
            avatarLayer
            
            // MARK: - Layer 3: Typography + Controls
            VStack {
                Spacer()
                
                foregroundContent
                    .opacity(viewModel.isTransitioning ? 0 : 1)
                    .offset(y: viewModel.isTransitioning ? 30 : 0)
                    .animation(DesignMotion.heroMaterialize, value: viewModel.isTransitioning)
                    .animation(DesignMotion.heroMaterialize, value: viewModel.currentStage)
            }
        }
        .colorScheme(.dark)
        .onChange(of: viewModel.selectedSkinTone) { newTone in
            avatarViewModel.updateSkinTone(to: newTone)
        }
        .onChange(of: viewModel.currentStage) { stage in
            // Avatar reactions per stage
            switch stage {
            case .welcome:
                avatarViewModel.resetToIdle()
            case .skinTone:
                avatarViewModel.setGlowIntensity(0.3)
            case .ready:
                // Wink + supernova glow
                withAnimation(DesignMotion.heroMaterialize) {
                    avatarViewModel.setExpression("avatar_eyes_winking")
                    avatarViewModel.setGlowIntensity(1.0)
                }
            default:
                avatarViewModel.setGlowIntensity(0.1)
            }
        }
        .onChange(of: viewModel.isComplete) { done in
            if done {
                onComplete(viewModel.userName, viewModel.selectedSkinTone, viewModel.selectedSkinType)
            }
        }
    }
    
    // MARK: - Background Layer
    
    private var backgroundLayer: some View {
        ZStack {
            DesignColors.voidObsidian.ignoresSafeArea()
            
            // Ambient orb that shifts gently
            Circle()
                .fill(DesignColors.roseGold.opacity(0.08))
                .frame(width: 600, height: 600)
                .blur(radius: 150)
                .offset(y: -100)
                .scaleEffect(viewModel.currentStage == .ready ? 1.5 : 1.0)
                .animation(DesignMotion.heroMaterialize, value: viewModel.currentStage)
        }
    }
    
    // MARK: - Avatar Layer (with Camera Zoom)
    
    private var avatarLayer: some View {
        AvatarRenderView(viewModel: avatarViewModel)
            .scaleEffect(viewModel.avatarScale)
            .offset(y: viewModel.avatarOffsetY)
            .animation(DesignMotion.heroMaterialize, value: viewModel.currentStage)
    }
    
    // MARK: - Foreground Content
    
    private var foregroundContent: some View {
        VStack(spacing: DesignSpacing.large) {
            
            // Question Text — Editorial Typography
            Text(viewModel.questionText)
                .font(DesignTypography.displayEditorial)
                .foregroundColor(DesignColors.luminousPearl)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .id(viewModel.currentStage) // Forces text re-render for transition
                .transition(.opacity.combined(with: .offset(y: 20)))
            
            // Stage-Specific Controls
            switch viewModel.currentStage {
            case .welcome:
                EmptyView() // Just the button below
                
            case .name:
                nameInput
                
            case .skinTone:
                skinTonePicker
                
            case .skinType:
                skinTypePicker
                
            case .ready:
                EmptyView() // Just the button below
            }
            
            // Primary CTA Button
            Button(action: { viewModel.advance() }) {
                Text(viewModel.buttonLabel)
                    .font(DesignTypography.titleUI)
                    .foregroundColor(DesignColors.voidObsidian)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSpacing.standard)
                    .background(
                        Capsule()
                            .fill(viewModel.canAdvance ? DesignColors.luminousPearl : DesignColors.voidAsh)
                    )
                    .shadow(color: DesignColors.luminousPearl.opacity(viewModel.canAdvance ? 0.15 : 0), radius: 20, y: 10)
            }
            .disabled(!viewModel.canAdvance)
            .padding(.horizontal, DesignSpacing.large)
            .animation(DesignMotion.editorialSpring, value: viewModel.canAdvance)
        }
        .padding(.horizontal, DesignSpacing.large)
        .padding(.bottom, DesignSpacing.heroic)
    }
    
    // MARK: - Name Input
    
    private var nameInput: some View {
        VStack(spacing: DesignSpacing.micro) {
            TextField("", text: $viewModel.userName, prompt: Text("Your name").foregroundColor(DesignColors.voidAsh))
                .font(.system(size: 24, weight: .light, design: .serif))
                .foregroundColor(DesignColors.luminousPearl)
                .multilineTextAlignment(.center)
                .padding(.vertical, DesignSpacing.standard)
            
            // Minimalist underline
            Rectangle()
                .fill(DesignColors.roseGold.opacity(0.6))
                .frame(height: 1)
                .frame(maxWidth: 200)
        }
        .transition(.opacity.combined(with: .offset(y: 20)))
    }
    
    // MARK: - Skin Tone Picker
    
    private var skinTonePicker: some View {
        HStack(spacing: DesignSpacing.standard) {
            ForEach(viewModel.skinToneOptions, id: \.name) { option in
                VStack(spacing: DesignSpacing.micro) {
                    Circle()
                        .fill(option.color)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle()
                                .stroke(DesignColors.luminousPearl, lineWidth: viewModel.selectedSkinTone == option.color ? 3 : 0)
                        )
                        .scaleEffect(viewModel.selectedSkinTone == option.color ? 1.15 : 1.0)
                        .animation(DesignMotion.tactilePress, value: viewModel.selectedSkinTone)
                    
                    Text(option.name)
                        .font(DesignTypography.microUI)
                        .foregroundColor(DesignColors.liquidSilver)
                }
                .onTapGesture {
                    viewModel.selectedSkinTone = option.color
                }
            }
        }
        .transition(.opacity.combined(with: .offset(y: 20)))
    }
    
    // MARK: - Skin Type Picker
    
    private var skinTypePicker: some View {
        VStack(spacing: DesignSpacing.standard) {
            ForEach(viewModel.skinTypeOptions, id: \.type) { option in
                Button(action: { viewModel.selectedSkinType = option.type }) {
                    HStack(spacing: DesignSpacing.standard) {
                        Image(systemName: option.icon)
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.selectedSkinType == option.type ? DesignColors.roseGold : DesignColors.liquidSilver)
                            .frame(width: 32)
                        
                        Text(option.label)
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(viewModel.selectedSkinType == option.type ? DesignColors.luminousPearl : DesignColors.liquidSilver)
                        
                        Spacer()
                        
                        if viewModel.selectedSkinType == option.type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignColors.roseGold)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, DesignSpacing.medium)
                    .padding(.vertical, DesignSpacing.standard)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignRadius.element, style: .continuous)
                            .stroke(
                                viewModel.selectedSkinType == option.type ? DesignColors.roseGold.opacity(0.5) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSpacing.standard)
        .transition(.opacity.combined(with: .offset(y: 20)))
    }
}
