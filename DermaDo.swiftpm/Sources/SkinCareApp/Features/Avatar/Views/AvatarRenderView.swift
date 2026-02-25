import SwiftUI

/// The pure UI component that renders the 2D minimalist avatar based on state.
/// This View performs NO logic. It only translates state into ZStack layers.
public struct AvatarRenderView: View {
    @ObservedObject var viewModel: AvatarViewModel
    @State private var isBreathing: Bool = false
    
    public init(viewModel: AvatarViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        let state = viewModel.state
        
        ZStack {
            // LAYER 1: The Ambient Glow
            Circle()
                .fill(DesignColors.roseGold.opacity(state.glowIntensity * 0.4))
                .blur(radius: 80)
                .scaleEffect(1.0 + (state.glowIntensity * 0.5))
                .scaleEffect(state.isVoiceListening ? 1.05 : 1.0)
                .animation(state.isVoiceListening ? Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : DesignMotion.editorialSpring, value: state.isVoiceListening)
            
            // LAYER 2: The Avatar Image
            Image("onboarding_avatar")
                .resizable()
                .scaledToFit()
                .frame(width: 280, height: 400)
                .overlay(
                    // Progress-driven skin brightness glow
                    Rectangle()
                        .fill(Color.white.opacity(state.skinBrightness * 0.3))
                        .blur(radius: 20)
                        .blendMode(.softLight)
                )
                .drawingGroup()
                // The character breathes gently
                .scaleEffect(isBreathing ? 1.01 : 1.00)
                .animation(
                    Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                    value: isBreathing
                )
            
            // LAYER 3: Contextual Overlay (Cleanser Foam, Mask)
            if state.activeOverlay == "avatar_overlay_cleanser" {
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 120, height: 80)
                    .blur(radius: 10)
                    .offset(y: 20)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if state.activeOverlay == "avatar_overlay_mask" {
                Rectangle()
                    .fill(DesignColors.ceruleanHydration.opacity(0.4))
                    .frame(width: 200, height: 260)
                    .blur(radius: 5)
                    .cornerRadius(40)
                    .offset(y: 0)
                    .transition(.opacity)
            }
        }
        .onAppear {
            isBreathing = true
        }
    }
}

