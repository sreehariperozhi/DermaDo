import Combine

// MARK: - SettingsManagerProtocol
/// Defines the contract for managing app settings and user preferences.
@MainActor
protocol SettingsManagerProtocol: AnyObject {
    var settingsPublisher: AnyPublisher<AppSettings, Never> { get }
    var onSettingsChanged: ((AppSettings) -> Void)? { get set }
    
    func loadSettings() -> AppSettings
    func saveSettings(_ settings: AppSettings)
    func updateTheme(_ theme: AppTheme)
    func resetToDefaults()
}
