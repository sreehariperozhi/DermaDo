import SwiftUI

/// The root 2.0 application layout that swaps between feature modules
/// based on the injected `AppRouter` state.
public struct AppMainView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var activeSession: ActiveRoutineSession
    @EnvironmentObject private var voiceManager: VoiceManager
    @EnvironmentObject private var dependencies: AppDependencies
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Force the entire 2.0 app into the Void background aesthetic
            DesignColors.voidObsidian
                .ignoresSafeArea()
            
            // The Router Switch: Swaps active views based on AppFeature state
            switch router.currentFeature {
            case .home:
                HomeDashboardView(viewModel: HomeDashboardViewModel(
                    routineManager: dependencies.routineManager,
                    trackerManager: dependencies.trackerManager,
                    settingsManager: dependencies.settingsManager,
                    progressManager: dependencies.progressManager
                ))
                    .transition(DesignMotion.editorialReveal)
            case .routine:
                RoutinesView()
                    .transition(DesignMotion.editorialReveal)
            case .tracker:
                TrackerView()
                    .transition(DesignMotion.editorialReveal)
            case .avatar:
                AvatarPlaygroundView(activeSession: activeSession, voiceManager: voiceManager)
                    .transition(DesignMotion.editorialReveal)
            case .settings:
                SettingsPlaygroundView()
                    .transition(DesignMotion.editorialReveal)
            }
            
            // Custom Luxury Navigation Bar sits visually over the void
            VStack {
                Spacer()
                AppNavigationBar()
            }
        }
        .colorScheme(.dark) // Force dark mode first on 2.0 shell
        .onAppear {
            if !hasCompletedOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: hasCompletedOnboarding) { newValue in
            if !newValue {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView { name, skinTone, skinType in
                // Persist user profile for personalization
                UserDefaults.standard.set(name, forKey: "userName")
                UserDefaults.standard.set(skinType.rawValue, forKey: "userSkinType")
                
                // Save skin tone color components for avatar persistence
                #if canImport(UIKit)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                UIColor(skinTone).getRed(&r, green: &g, blue: &b, alpha: &a)
                UserDefaults.standard.set([Double(r), Double(g), Double(b)], forKey: "userSkinToneRGB")
                #endif
                
                withAnimation(DesignMotion.heroMaterialize) {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
            }
        }
    }
}

/// The luxury floating segmented controller that replaces standard TabView
struct AppNavigationBar: View {
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        HStack(spacing: DesignSpacing.medium) {
            navButton(for: .home, iconSystemName: "rectangle.3.group")
            navButton(for: .routine, iconSystemName: "list.clipboard")
            navButton(for: .tracker, iconSystemName: "face.dashed")
            navButton(for: .avatar, iconSystemName: "sparkles")
            navButton(for: .settings, iconSystemName: "slider.horizontal.3")
        }
        .padding(.horizontal, DesignSpacing.large)
        .padding(.vertical, DesignSpacing.standard)
        // Glassmorphism floating pill
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(DesignShadows.innerGlow, lineWidth: 1)
        )
        .padding(.bottom, DesignSpacing.standard)
        .depthShadow() // Give it high mass/float
    }
    
    @ViewBuilder
    private func navButton(for feature: AppFeature, iconSystemName: String) -> some View {
        let isActive = router.currentFeature == feature
        
        Button(action: {
            router.navigate(to: feature)
        }) {
            Image(systemName: iconSystemName)
                .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? DesignColors.roseGold : DesignColors.liquidSilver)
                .frame(width: 44, height: 44) // Standard massive touch target
                .background(
                    Circle()
                        .fill(isActive ? DesignColors.voidAsh.opacity(0.8) : Color.clear)
                )
                .scaleEffect(isActive ? 1.05 : 1.0)
                .animation(DesignMotion.editorialSpring, value: isActive)
        }
        .buttonStyle(.plain)
    }
}
