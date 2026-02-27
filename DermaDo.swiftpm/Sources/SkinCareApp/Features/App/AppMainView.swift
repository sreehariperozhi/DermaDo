import SwiftUI

/// The root 2.0 application layout that swaps between feature modules
/// based on the injected `AppRouter` state.
public struct AppMainView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var activeSession: ActiveRoutineSession
    @EnvironmentObject private var voiceManager: VoiceManager
    @EnvironmentObject private var dependencies: AppDependencies
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Force the entire 2.0 app into the Void background aesthetic
            DesignColors.voidObsidian
                .ignoresSafeArea()
            
            // The TabView: Enables horizontal swipe navigation between feature modules
            TabView(selection: $router.currentFeature) {
                HomeDashboardView(viewModel: HomeDashboardViewModel(
                    routineManager: dependencies.routineManager,
                    trackerManager: dependencies.trackerManager,
                    settingsManager: dependencies.settingsManager,
                    progressManager: dependencies.progressManager,
                    userManager: dependencies.userManager
                ))
                .tag(AppFeature.home)
                
                RoutinesView()
                    .tag(AppFeature.routine)
                
                TrackerView()
                    .tag(AppFeature.tracker)
                
                SettingsView()
                    .tag(AppFeature.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .safeAreaInset(edge: .bottom) {
                AppNavigationBar()
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
            navButton(for: .settings, iconSystemName: "slider.horizontal.3")
        }
        .padding(.horizontal, DesignSpacing.large)
        .padding(.vertical, DesignSpacing.standard)
        // Glassmorphism floating pill
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(DesignShadows.innerGlow, lineWidth: 0.5)
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
