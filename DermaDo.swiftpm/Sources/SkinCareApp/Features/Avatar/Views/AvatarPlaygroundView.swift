import SwiftUI

/// A developer console and user testing ground for the 2D minimalist avatar.
public struct AvatarPlaygroundView: View {
    @EnvironmentObject private var activeSession: ActiveRoutineSession
    @StateObject private var viewModel: AvatarViewModel
    
    // Example test skin tones
    let skinTones: [Color] = [
        DesignColors.sandalwoodMedium,
        Color(hex: "#FFDAC1"), // Fair
        Color(hex: "#E0AC69"), // Olive
        Color(hex: "#8D5524") // Deep
    ]
    
    public init() {
        // We defer creation of the ViewModel so it can capture the environment object later
        // However, since we can't cleanly access Environment objects in pure init() for StateObject injection directly,
        // we will let the view spin up its own state object using a custom initializer structure if needed, or pass it explicitly.
        // For simplicity in this Playground, we will use an explicit init.
        _viewModel = StateObject(wrappedValue: AvatarViewModel(activeSession: nil)) 
    }
    
    // A secondary init that takes the session directly for cleaner DI
    public init(activeSession: ActiveRoutineSession, voiceManager: VoiceManager) {
        _viewModel = StateObject(wrappedValue: AvatarViewModel(activeSession: activeSession, voiceManager: voiceManager))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // The Canvas
            ZStack {
                DesignColors.voidObsidian.ignoresSafeArea()
                
                AvatarRenderView(viewModel: viewModel)
                    .editorialReveal(delay: 0.2)
            }
            .frame(maxHeight: .infinity)
            
            // The Control Panel
            VStack(spacing: DesignSpacing.heroic) {
                
                // SKINTONE CONTROLS
                VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                    Text("SKIN TONE")
                        .font(DesignTypography.captionUI)
                        .captionTracking()
                        .foregroundColor(DesignColors.liquidSilver)
                    
                    HStack(spacing: DesignSpacing.standard) {
                        ForEach(skinTones, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(DesignColors.luminousPearl, lineWidth: viewModel.state.skinTone == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    viewModel.updateSkinTone(to: color)
                                }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // REACTION CONTROLS
                VStack(alignment: .leading, spacing: DesignSpacing.medium) {
                    Text("ROUTINE REACTIONS")
                        .font(DesignTypography.captionUI)
                        .captionTracking()
                        .foregroundColor(DesignColors.liquidSilver)
                    
                    HStack(spacing: DesignSpacing.standard) {
                        Button("Cleanser") {
                            activeSession.currentStep = .cleanser
                        }
                        .primaryButtonStyle()
                        
                        Button("Mask") {
                            activeSession.currentStep = .mask
                        }
                        .primaryButtonStyle()
                        
                        Button("Idle") {
                            activeSession.currentStep = .none
                            viewModel.resetToIdle()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(DesignColors.liquidSilver)
                        .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
            .padding(DesignSpacing.heroic)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 30, y: -10)
        }
        .colorScheme(.dark)
    }
}
