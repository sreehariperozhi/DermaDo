import Foundation
import UIKit

// MARK: - BackupManagerProtocol
@MainActor
protocol BackupManagerProtocol: AnyObject {
    func exportData(completion: @escaping @Sendable (Result<URL, Error>) -> Void)
    func importData(from url: URL, completion: @escaping @Sendable (Result<Void, Error>) -> Void)
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
@MainActor
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
    
    func exportData(completion: @escaping @Sendable (Result<URL, Error>) -> Void) {
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
            
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Import
    
    func importData(from url: URL, completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        // We'll need access to the security scoped resource if coming from Files app
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        do {
            // 1. Decode Payload
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(BackupPayload.self, from: data)
            
            // 2. Restore Images
            for (filename, base64) in payload.images {
                if let imageData = Data(base64Encoded: base64) {
                    _ = try? self.dataManager.saveImage(imageData, withName: filename)
                }
            }
            
            // 3. Restore Data
            for routine in payload.routines { self.routineManager.saveRoutine(routine) }
            for product in payload.products { self.productManager.saveProduct(product) }
            for entry in payload.skinEntries {
                self.trackerManager.saveEntry(entry)
            }
            
            // Achievements: Overwrite via DataManager
            try self.dataManager.saveCollection(payload.achievements, forKey: DataManager.StorageKey.achievements)
            
            // Settings
            if let settings = payload.settings {
                self.settingsManager.saveSettings(settings)
            }
            
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }
}
