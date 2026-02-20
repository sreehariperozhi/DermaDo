import Foundation
import Combine

// MARK: - TrackerManagerProtocol
/// Defines the contract for managing skin tracking log entries.
protocol TrackerManagerProtocol: AnyObject {
    var entriesPublisher: AnyPublisher<[SkinEntry], Never> { get }
    var onEntriesChanged: (([SkinEntry]) -> Void)? { get set }
    
    func fetchAllEntries() -> [SkinEntry]
    func fetchEntry(byId id: UUID) -> SkinEntry?
    func saveEntry(_ entry: SkinEntry)
    func deleteEntry(byId id: UUID)
}
