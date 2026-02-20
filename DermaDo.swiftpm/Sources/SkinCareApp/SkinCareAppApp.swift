import SwiftUI

@main
struct SkinCareAppApp: App {
    // Maintain a single instance of dependencies
    @StateObject private var dependencies = AppDependencies()
    @AppStorage("appTheme") private var storedTheme: String = AppTheme.system.rawValue
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
            AppMainView()
                .environmentObject(appRouter)
                .environmentObject(activeSession)
                .environmentObject(voiceManager)
                .environmentObject(dependencies)
                .preferredColorScheme(colorScheme)
                .onAppear {
                    performStartupChecks()
                    // Sync stored theme from settings
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
        
        // Notification Request - Manager handles delegate in init
        // Just request auth if not determind? 
        // Or let a specific view (Onboarding/Settings) handle this to avoid prompt bomb on launch?
        // User request implied keeping logic but wrapping it. 
        // Current logic requests on launch.
        dependencies.notificationManager.requestAuthorization { granted in
            if granted {
                print("[SkinCareApp] Notifications authorized")
            } else {
                print("[SkinCareApp] Notifications denied")
            }
        }
    }
}
