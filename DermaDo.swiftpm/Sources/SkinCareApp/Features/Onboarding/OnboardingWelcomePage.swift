import SwiftUI

/// Page 1: Welcome screen with app logo, title, and brand-aligned subtitle.
struct OnboardingWelcomePage: View {
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: DesignSpacing.large) {
            Spacer()
            
            // App Logo / Avatar
            Image("onboarding_avatar")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220, maxHeight: 220)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(DesignColors.roseGold.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: DesignColors.roseGold.opacity(0.2), radius: 30, y: 10)
                .scaleEffect(appeared ? 1.0 : 0.85)
                .opacity(appeared ? 1.0 : 0)
            
            VStack(spacing: DesignSpacing.standard) {
                Text("Welcome to")
                    .font(DesignTypography.headerEditorial)
                    .foregroundColor(DesignColors.liquidSilver)
                    .opacity(appeared ? 1.0 : 0)
                
                Text("DermaDo")
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.luminousPearl)
                    .editorialTracking()
                    .opacity(appeared ? 1.0 : 0)
                
                Text("Your personal skincare companion.\nBuild routines, track progress, glow daily.")
                    .font(DesignTypography.bodyUI)
                    .foregroundColor(DesignColors.liquidSilver)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignSpacing.large)
                    .opacity(appeared ? 1.0 : 0)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(DesignMotion.heroMaterialize) {
                appeared = true
            }
        }
    }
}
