import Foundation
import UIKit

// MARK: - DataManager
/// Production implementation of `DataManagerProtocol`.
///
/// **Storage layout** (inside Documents):
/// ```
/// Documents/
/// ├── data/
/// │   ├── routines.json
/// │   ├── products.json
/// │   ├── skin_entries.json
/// │   ├── achievements.json
/// │   ├── settings.json
/// │   └── schema_version.json
/// └── images/
///     ├── <uuid>.jpg
///     └── ...
/// ```
///
/// All writes are **atomic** (write to temp → rename) to prevent data loss on crash.
/// Decoding failures are caught and logged, returning `nil` / `[]` instead of crashing.
import Combine

// MARK: - DataManager
/// Production implementation of `DataManagerProtocol`.
/// ... (docs) ...
@MainActor
final class DataManager: DataManagerProtocol, ObservableObject {
    
    // MARK: - Observability
    
    let dataChanged = PassthroughSubject<String, Never>()

    // MARK: - Constants

    /// Increment this when model schemas change. Migration logic handles upgrades.
    static let latestSchemaVersion: Int = 1

    /// Well-known storage keys for each domain.
    enum StorageKey {
        static let routines     = "routines"
        static let products     = "products"
        static let skinEntries  = "skin_entries"
        static let achievements = "achievements"
        static let settings     = "settings"
        static let userProfile  = "user_profile"
        static let progress      = "progress"
        static let schemaVersion = "schema_version"
    }

    // MARK: - Private Properties

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    /// Root of the data directory: `<Documents>/data/`
    private let dataDirectoryURL: URL

    /// Root of the images directory: `<Documents>/images/`
    private let imagesDirectoryURL: URL

    // MARK: - Initialization

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        // Configure encoder
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        // Configure decoder
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        // Build directory URLs
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Critical: Could not access Documents directory.")
        }
        self.dataDirectoryURL   = documentsURL.appendingPathComponent("data", isDirectory: true)
        self.imagesDirectoryURL = documentsURL.appendingPathComponent("images", isDirectory: true)

        // Ensure directories exist
        createDirectoryIfNeeded(at: dataDirectoryURL)
        createDirectoryIfNeeded(at: imagesDirectoryURL)
    }

    // MARK: - Generic JSON Persistence

    func save<T: Codable>(_ object: T, forKey key: String) throws {
        let data: Data
        do {
            data = try encoder.encode(object)
        } catch {
            let message = "Key '\(key)': \(error.localizedDescription)"
            logError(message)
            throw DataManagerError.encodingFailed(message)
        }

        let fileURL = dataFileURL(forKey: key)
        do {
            try atomicWrite(data: data, to: fileURL)
        } catch {
            let message = "Key '\(key)': \(error.localizedDescription)"
            logError(message)
            throw DataManagerError.writeFailed(message)
        }

        logInfo("Saved data for key '\(key)' (\(data.count) bytes)")
        dataChanged.send(key)
    }

    func load<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        let fileURL = dataFileURL(forKey: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            logInfo("No data file found for key '\(key)'")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let object = try decoder.decode(type, from: data)
            logInfo("Loaded data for key '\(key)'")
            return object
        } catch {
            logError("Decoding failed for key '\(key)': \(error.localizedDescription)")
            // Preserve the corrupt file for debugging instead of deleting
            backupCorruptFile(at: fileURL, key: key)
            return nil
        }
    }

    func delete(forKey key: String) throws {
        let fileURL = dataFileURL(forKey: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            try fileManager.removeItem(at: fileURL)
            logInfo("Deleted data for key '\(key)'")
            dataChanged.send(key)
        } catch {
            let message = "Key '\(key)': \(error.localizedDescription)"
            logError(message)
            throw DataManagerError.deleteFailed(message)
        }
    }

    func exists(forKey key: String) -> Bool {
        let fileURL = dataFileURL(forKey: key)
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - Collection Convenience

    func saveCollection<T: Codable>(_ objects: [T], forKey key: String) throws {
        try save(objects, forKey: key)
    }

    func loadCollection<T: Codable>(forKey key: String, as type: T.Type) -> [T] {
        return load(forKey: key, as: [T].self) ?? []
    }

    // MARK: - Image Storage

    func saveImage(_ data: Data, withName name: String) throws -> String {
        let fileURL = imagesDirectoryURL.appendingPathComponent(name)

        do {
            try atomicWrite(data: data, to: fileURL)
            logInfo("Saved image '\(name)' (\(data.count) bytes)")
            return name
        } catch {
            let message = "Image '\(name)': \(error.localizedDescription)"
            logError(message)
            throw DataManagerError.imageWriteFailed(message)
        }
    }

    func loadImage(named name: String) -> Data? {
        let fileURL = imagesDirectoryURL.appendingPathComponent(name)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            logInfo("No image found named '\(name)'")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            logInfo("Loaded image '\(name)' (\(data.count) bytes)")
            return data
        } catch {
            logError("Image read failed '\(name)': \(error.localizedDescription)")
            return nil
        }
    }

    func deleteImage(named name: String) throws {
        let fileURL = imagesDirectoryURL.appendingPathComponent(name)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }

        do {
            try fileManager.removeItem(at: fileURL)
            logInfo("Deleted image '\(name)'")
        } catch {
            let message = "Image '\(name)': \(error.localizedDescription)"
            logError(message)
            throw DataManagerError.deleteFailed(message)
        }
    }

    // MARK: - Migration

    var currentSchemaVersion: Int {
        return load(forKey: StorageKey.schemaVersion, as: Int.self) ?? 0
    }

    func migrateIfNeeded() throws {
        let stored = currentSchemaVersion
        let latest = DataManager.latestSchemaVersion

        guard stored < latest else {
            logInfo("Schema up to date (v\(stored))")
            return
        }

        logInfo("Migrating schema from v\(stored) to v\(latest)...")

        // Back up all data files before migration
        try backupDataDirectory()

        // Run incremental migration steps
        do {
            for version in stored..<latest {
                try performMigration(from: version, to: version + 1)
            }
            try save(latest, forKey: StorageKey.schemaVersion)
            logInfo("Migration complete → v\(latest)")
        } catch {
            let message = "v\(stored)→v\(latest): \(error.localizedDescription)"
            logError("Migration failed: \(message)")
            throw DataManagerError.migrationFailed(message)
        }
    }

    // MARK: - Private — Migration Steps

    /// Override individual migration steps here as the schema evolves.
    private func performMigration(from oldVersion: Int, to newVersion: Int) throws {
        switch (oldVersion, newVersion) {
        case (0, 1):
            // Initial schema — no transformation needed, just stamp the version.
            logInfo("Migration v0→v1: stamping initial schema version")
        default:
            logInfo("No migration action for v\(oldVersion)→v\(newVersion)")
        }
    }

    // MARK: - Private — Atomic Write

    /// Writes data to a temporary file first, then atomically renames it to the
    /// target URL. This guarantees the target file is never partially written.
    private func atomicWrite(data: Data, to targetURL: URL) throws {
        let tempURL = targetURL
            .deletingLastPathComponent()
            .appendingPathComponent(UUID().uuidString + ".tmp")

        try data.write(to: tempURL, options: [.atomic])

        // `.atomic` already does temp-file → rename under the hood on Apple platforms,
        // but we wrap it in this method for clarity and future cross-platform safety.
        // If the file already exists, remove it first so the rename succeeds.
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        try fileManager.moveItem(at: tempURL, to: targetURL)
    }

    // MARK: - Private — Backup

    /// Creates a timestamped backup of the entire data directory before migration.
    private func backupDataDirectory() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())

        let backupURL = dataDirectoryURL
            .deletingLastPathComponent()
            .appendingPathComponent("data_backup_\(timestamp)", isDirectory: true)

        guard fileManager.fileExists(atPath: dataDirectoryURL.path) else { return }

        do {
            try fileManager.copyItem(at: dataDirectoryURL, to: backupURL)
            logInfo("Backed up data directory to \(backupURL.lastPathComponent)")
        } catch {
            let message = "Backup failed: \(error.localizedDescription)"
            logError(message)
            throw DataManagerError.migrationFailed(message)
        }
    }

    /// Renames a corrupt file so it isn't lost but won't block future loads.
    private func backupCorruptFile(at url: URL, key: String) {
        let corruptURL = url.deletingLastPathComponent()
            .appendingPathComponent("\(key)_corrupt_\(Int(Date().timeIntervalSince1970)).json")
        do {
            try fileManager.moveItem(at: url, to: corruptURL)
            logInfo("Moved corrupt file to \(corruptURL.lastPathComponent)")
        } catch {
            logError("Could not back up corrupt file for key '\(key)': \(error.localizedDescription)")
        }
    }

    // MARK: - Private — Helpers

    private func dataFileURL(forKey key: String) -> URL {
        return dataDirectoryURL.appendingPathComponent("\(key).json")
    }

    private func createDirectoryIfNeeded(at url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            logInfo("Created directory at \(url.lastPathComponent)")
        } catch {
            logError("Directory creation failed at \(url.path): \(error.localizedDescription)")
        }
    }

    // MARK: - Private — Logging

    /// Centralized info-level log. Replace with OSLog / unified logging in production.
    private func logInfo(_ message: String) {
        #if DEBUG
        print("[DataManager ℹ️] \(message)")
        #endif
    }

    /// Centralized error-level log.
    private func logError(_ message: String) {
        print("[DataManager ❌] \(message)")
    }
}
