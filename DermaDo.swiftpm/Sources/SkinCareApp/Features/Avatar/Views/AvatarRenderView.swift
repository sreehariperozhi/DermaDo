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
            
<<<<<<< HEAD
            // LAYER 2: The Character ZStack
            ZStack {
                // Base Body (Tinted by Skin Tone configuration)
                // In production, this would be an SVG. We use a capsule placeholder for the skeleton.
                Capsule()
                    .fill(state.skinTone)
                    .frame(width: 140, height: 260)
                    .offset(y: 40)
                    .overlay(
                        // Progress-driven skin brightness glow
                        Capsule()
                            .fill(Color.white.opacity(state.skinBrightness * 0.5))
                            .blur(radius: 4)
                    )
                    .overlay(
                        // Simulate a neck/chin line
                        Capsule()
                            .stroke(Color.black.opacity(0.1), lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .animation(DesignMotion.heroMaterialize, value: state.skinBrightness)
                
                // Hair Layer
                if state.hairStyle == "avatar_hair_default" {
                    // Placeholder for SVG
                    Path { path in
                        path.addArc(center: CGPoint(x: 100, y: 100), radius: 80, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                    }
                    .fill(DesignColors.voidObsidian)
                    .frame(width: 200, height: 100)
                    .offset(y: -90)
                }
                
                // Outfit Layer
                if state.outfit == "avatar_outfit_robe" {
                    // Placeholder for SVG robe
                    RoundedRectangle(cornerRadius: 16)
                        .fill(DesignColors.luminousPearl)
                        .frame(width: 180, height: 120)
                        .offset(y: 110)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                }
                
                // Eyes / Expression
                HStack(spacing: 36) {
                    if state.expression == "avatar_eyes_closed" {
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 24, height: 4)
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 24, height: 4)
                    } else if state.expression == "avatar_eyes_winking" {
                        Circle().fill(Color.black.opacity(0.7)).frame(width: 16, height: 16)
                        Capsule().fill(Color.black.opacity(0.6)).frame(width: 20, height: 4)
                    } else { // avatar_eyes_open
                        Circle().fill(Color.black.opacity(0.7)).frame(width: 16, height: 16)
                        Circle().fill(Color.black.opacity(0.7)).frame(width: 16, height: 16)
                    }
                }
                .offset(y: -20)
                
                // Contextual Overlay (Cleanser Foam, Mask)
                if let overlayName = state.activeOverlay {
                    Image(overlayName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .opacity(0.7) // Within 0.6–0.8 range for a refined look
                        .offset(y: overlayName == "avatar_overlay_cleanser" ? 10 : 0)
                        .transition(.opacity.animation(.easeInOut(duration: 0.4))) // Smooth 0.4s fade-in
                }
=======
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
>>>>>>> mac-ui-major-backup
            }
        }
        .onAppear {
            isBreathing = true
        }
    }
}

