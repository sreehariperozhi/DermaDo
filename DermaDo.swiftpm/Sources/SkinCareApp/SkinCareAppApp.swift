import SwiftUI

@main
struct SkinCareAppApp: App {
    // Maintain a single instance of dependencies
    @StateObject private var dependencies = AppDependencies()
    @AppStorage("appTheme") private var storedTheme: String = AppTheme.system.rawValue
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted = false
    @StateObject private var appRouter = AppRouter()
    @StateObject private var activeSession = ActiveRoutineSession()
    @StateObject private var voiceManager = VoiceManager()

    private var colorScheme: ColorScheme? {
        switch AppTheme(rawValue: storedTheme) ?? .system {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboardingCompleted {
                    AppMainView()
                } else {
                    OnboardingView(
                        userManager: dependencies.userManager,
                        notificationManager: dependencies.notificationManager
                    )
                }
            }
            .environmentObject(appRouter)
            .environmentObject(activeSession)
            .environmentObject(voiceManager)
            .environmentObject(dependencies)
            .preferredColorScheme(colorScheme)
            .animation(DesignMotion.editorialSpring, value: isOnboardingCompleted)
            .onAppear {
                performStartupChecks()
                let theme = dependencies.settingsManager.loadSettings().theme
                storedTheme = theme.rawValue
            }
            .onReceive(dependencies.settingsManager.settingsPublisher) { settings in
                storedTheme = settings.theme.rawValue
            }
        }
    }
    
    private func performStartupChecks() {
        // Migration
        do {
            try dependencies.dataManager.migrateIfNeeded()
        } catch {
            print("[SkinCareApp] Migration failed: \(error.localizedDescription)")
        }
        
        // Notification auth is now handled by the Onboarding flow or Settings.
        // Only auto-request if onboarding has already been completed.
        if isOnboardingCompleted {
            dependencies.notificationManager.requestAuthorization { granted in
                if granted {
                    print("[SkinCareApp] Notifications authorized")
                } else {
                    print("[SkinCareApp] Notifications denied")
                }
            }
        }
    }
}
