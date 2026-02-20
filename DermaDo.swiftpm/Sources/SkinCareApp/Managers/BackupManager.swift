import Foundation
import UIKit

// MARK: - BackupManagerProtocol
protocol BackupManagerProtocol: AnyObject {
    func exportData(completion: @escaping (Result<URL, Error>) -> Void)
    func importData(from url: URL, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - BackupPayload
/// Represents the full application state for export/import.
/// Images are encoded as Base64 strings to create a single portable JSON file.
struct BackupPayload: Codable {
    let schemaVersion: Int
    let routines: [Routine]
    let products: [Product]
    let skinEntries: [SkinEntry]
    let achievements: [Achievement]
    let settings: AppSettings?
    
    // Map of filename -> base64 string
    let images: [String: String]
}

// MARK: - BackupManager
final class BackupManager: BackupManagerProtocol {
    
    // MARK: - Dependencies
    private let dataManager: DataManagerProtocol
    private let routineManager: RoutineManagerProtocol
    private let productManager: ProductManagerProtocol
    private let trackerManager: TrackerManagerProtocol
    private let achievementManager: AchievementManagerProtocol
    private let settingsManager: SettingsManagerProtocol
    
    // MARK: - Init
    init(
        dataManager: DataManagerProtocol,
        routineManager: RoutineManagerProtocol,
        productManager: ProductManagerProtocol,
        trackerManager: TrackerManagerProtocol,
        achievementManager: AchievementManagerProtocol,
        settingsManager: SettingsManagerProtocol
    ) {
        self.dataManager = dataManager
        self.routineManager = routineManager
        self.productManager = productManager
        self.trackerManager = trackerManager
        self.achievementManager = achievementManager
        self.settingsManager = settingsManager
    }
    
    // MARK: - Export
    
    func exportData(completion: @escaping (Result<URL, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                // 1. Gather all data
                let routines = self.routineManager.fetchAllRoutines()
                let products = self.productManager.fetchAllProducts()
                let entries = self.trackerManager.fetchAllEntries()
                let achievements = self.achievementManager.fetchAllAchievements()
                let settings = self.settingsManager.loadSettings()
                
                // 2. Gather images
                var images: [String: String] = [:]
                for entry in entries {
                    if let filename = entry.photoFileName,
                       let data = self.dataManager.loadImage(named: filename) {
                        images[filename] = data.base64EncodedString()
                    }
                }
                
                // 3. Create Payload
                let payload = BackupPayload(
                    schemaVersion: DataManager.latestSchemaVersion,
                    routines: routines,
                    products: products,
                    skinEntries: entries,
                    achievements: achievements,
                    settings: settings,
                    images: images
                )
                
                // 4. Encode to JSON
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(payload)
                
                // 5. Save to temporary file
                let tempDir = FileManager.default.temporaryDirectory
                let filename = "SkinCareBackup_\(self.dateString()).json"
                let fileURL = tempDir.appendingPathComponent(filename)
                try data.write(to: fileURL)
                
                DispatchQueue.main.async { completion(.success(fileURL)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
    
    // MARK: - Import
    
    func importData(from url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // We'll need access to the security scoped resource if coming from Files app
        let accessing = url.startAccessingSecurityScopedResource()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            
            do {
                // 1. Decode Payload
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let payload = try decoder.decode(BackupPayload.self, from: data)
                
                // 2. Restore Images
                // Note: We should probably clear existing images first or overwrite conflicts?
                // Importing *overwrites* current state usually. Or merges?
                // Given "Import", simpler to replace or append.
                // IDs are UUIDs. If we overwrite existing IDs, we update. New IDs append.
                // BUT "Combine all JSON" request might imply merge? user said "Implement local data export... also implement import".
                // Usually backups restore state. Let's start with a loop that saves everything.
                
                for (filename, base64) in payload.images {
                    if let imageData = Data(base64Encoded: base64) {
                        _ = try? self.dataManager.saveImage(imageData, withName: filename)
                    }
                }
                
                // 3. Restore Data (Merge/Overwrite logic)
                for routine in payload.routines { self.routineManager.saveRoutine(routine) }
                for product in payload.products { self.productManager.saveProduct(product) }
                for entry in payload.skinEntries {
                    // Save entry directly (TrackerManager adds to array)
                    // We need a way to bulk save or just loop save. Loop is fine.
                    self.trackerManager.saveEntry(entry)
                }
                
                // Achievements: Merge?
                // DataManager just overwrites collection normally.
                // Let's use DataManager's saveCollection directly to batch?
                // But managers have logic (notifications etc).
                // Safest to go through managers.
                // ProductManager schedules expiry. RoutineManager schedules reminders.
                // So calling save...() is correct to trigger side effects.
                
                // Achievements might be tricky. Usually computed.
                // But we persist them. Let's just save.
                // AchievementManager doesn't expose save directly, only evaluate.
                // Wait, logic: "Update achievements automatically when routine is completed".
                // If we import old achievements, we should respect them.
                // We'll trust the payload's state.
                // We need to expose a direct save or just overwrite the file via DataManager?
                // AchievementManager uses `saveCollection` privately.
                // I'll add a helper or just use DataManager if I can access it.
                // `DataManager` is injected. I can use it directly for Achievements since it's just data.
                try self.dataManager.saveCollection(payload.achievements, forKey: DataManager.StorageKey.achievements)
                
                // Settings
                if let settings = payload.settings {
                    self.settingsManager.saveSettings(settings)
                }
                
                DispatchQueue.main.async { completion(.success(())) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }
    }
    
    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }
}
