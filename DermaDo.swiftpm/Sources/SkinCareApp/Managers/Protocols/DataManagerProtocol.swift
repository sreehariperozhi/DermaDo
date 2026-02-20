import Foundation

// MARK: - DataManagerError
/// Errors that can occur during data persistence operations.
enum DataManagerError: LocalizedError {
    case encodingFailed(String)
    case decodingFailed(String)
    case writeFailed(String)
    case readFailed(String)
    case deleteFailed(String)
    case directoryCreationFailed(String)
    case imageWriteFailed(String)
    case imageReadFailed(String)
    case migrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let detail):   return "Encoding failed: \(detail)"
        case .decodingFailed(let detail):   return "Decoding failed: \(detail)"
        case .writeFailed(let detail):      return "Write failed: \(detail)"
        case .readFailed(let detail):       return "Read failed: \(detail)"
        case .deleteFailed(let detail):     return "Delete failed: \(detail)"
        case .directoryCreationFailed(let detail): return "Directory creation failed: \(detail)"
        case .imageWriteFailed(let detail): return "Image write failed: \(detail)"
        case .imageReadFailed(let detail):  return "Image read failed: \(detail)"
        case .migrationFailed(let detail):  return "Migration failed: \(detail)"
        }
    }
}

import Combine

// MARK: - DataManagerProtocol
/// Defines the contract for generic local data persistence.
/// Supports the offline-first architecture by abstracting storage operations.
protocol DataManagerProtocol: AnyObject {
    
    /// Emits the key of the data that changed.
    var dataChanged: PassthroughSubject<String, Never> { get }

    // MARK: - Generic JSON Persistence

    /// Saves a Codable object to disk as JSON with atomic write protection.
    func save<T: Codable>(_ object: T, forKey key: String) throws

    /// Loads a Codable object from disk.
    func load<T: Codable>(forKey key: String, as type: T.Type) -> T?

    /// Deletes the file associated with a key.
    func delete(forKey key: String) throws

    /// Returns true if data exists on disk for the given key.
    func exists(forKey key: String) -> Bool

    // MARK: - Collection Convenience

    /// Saves an array of Codable objects.
    func saveCollection<T: Codable>(_ objects: [T], forKey key: String) throws

    /// Loads an array of Codable objects, returning empty array on failure.
    func loadCollection<T: Codable>(forKey key: String, as type: T.Type) -> [T]

    // MARK: - Image Storage

    /// Saves image data to the images directory. Returns the generated file name.
    func saveImage(_ data: Data, withName name: String) throws -> String

    /// Loads image data by file name.
    func loadImage(named name: String) -> Data?

    /// Deletes an image file by name.
    func deleteImage(named name: String) throws

    // MARK: - Migration

    /// Returns the current data schema version stored on disk.
    var currentSchemaVersion: Int { get }

    /// Performs any necessary migration from old schema versions.
    func migrateIfNeeded() throws
}
