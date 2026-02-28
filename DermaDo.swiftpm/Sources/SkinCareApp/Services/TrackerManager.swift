import Foundation
import Combine

// MARK: - TrackerManager
/// Manages skin tracking entries using DataManager for persistence.
@MainActor
final class TrackerManager: TrackerManagerProtocol, ObservableObject {

    // MARK: - Dependencies

    private let dataManager: DataManagerProtocol

    // MARK: - Published State
    
    @Published private(set) var entries: [SkinEntry] = [] {
        didSet {
            onEntriesChanged?(entries)
        }
    }
    
    var entriesPublisher: AnyPublisher<[SkinEntry], Never> {
        $entries.eraseToAnyPublisher()
    }
    
    // MARK: - Callbacks
    
    var onEntriesChanged: (([SkinEntry]) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(dataManager: DataManagerProtocol = DataManager()) {
        self.dataManager = dataManager
        
        loadEntries()
        setupDetailedObservations()
    }
    
    private func setupDetailedObservations() {
        dataManager.dataChanged
            .filter { $0 == DataManager.StorageKey.skinEntries }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadEntries()
            }
            .store(in: &cancellables)
    }
    
    private func loadEntries() {
        self.entries = dataManager.loadCollection(forKey: DataManager.StorageKey.skinEntries, as: SkinEntry.self)
    }

    // MARK: - TrackerManagerProtocol

    func fetchAllEntries() -> [SkinEntry] {
        return entries
    }

    func fetchEntry(byId id: UUID) -> SkinEntry? {
        return entries.first { $0.id == id }
    }

    func saveEntry(_ entry: SkinEntry) {
        var currentEntries = entries
        if let index = currentEntries.firstIndex(where: { $0.id == entry.id }) {
            currentEntries[index] = entry
        } else {
            currentEntries.append(entry)
        }
        
        // Optimistic update
        self.entries = currentEntries
        
        // Persist
        try? dataManager.saveCollection(currentEntries, forKey: DataManager.StorageKey.skinEntries)
        // onEntriesChanged triggered by didSet
    }

    func deleteEntry(byId id: UUID) {
        var currentEntries = entries
        currentEntries.removeAll { $0.id == id }
        
        // Optimistic update
        self.entries = currentEntries
        
        // Persist
        try? dataManager.saveCollection(currentEntries, forKey: DataManager.StorageKey.skinEntries)
        // onEntriesChanged triggered by didSet
    }
}
