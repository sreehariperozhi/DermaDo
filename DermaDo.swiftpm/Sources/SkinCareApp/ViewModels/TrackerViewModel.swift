import SwiftUI
import UIKit
import Combine

// MARK: - TrackerViewModel
/// Drives the Tracker screen: entry list, weekly/monthly graph data, analytics.
class TrackerViewModel: ObservableObject {

    // MARK: - Dependencies

    // MARK: - Dependencies

    private let trackerManager: TrackerManagerProtocol
    private let dataManager: DataManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    enum Period: Int, CaseIterable { case week, month }
    @Published var selectedPeriod: Period = .week {
        didSet { recalculate() }
    }

    @Published var allEntries: [SkinEntry] = []
    @Published var periodEntries: [SkinEntry] = []
    
    // Analytics
    @Published var averageOil: Double = 0
    @Published var averageDryness: Double = 0
    @Published var averageRedness: Double = 0
    @Published var averageAcne: Double = 0
    @Published var totalEntries: Int = 0
    
    // MARK: - Initialization

    init(trackerManager: TrackerManagerProtocol, dataManager: DataManagerProtocol) {
        self.trackerManager = trackerManager
        self.dataManager = dataManager
        
        // Bind to manager's data
        trackerManager.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEntries in
                self?.allEntries = newEntries.sorted { $0.date > $1.date }
                self?.recalculate()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Processing
    
    private func recalculate() {
        totalEntries = allEntries.count
        filterByPeriod()
        computeAverages()
    }
    
    // refresh() is deprecated in favor of reactive updates
    func refresh() {
       // No-op
    }

    // MARK: - Period Filtering

    private func filterByPeriod() {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date

        switch selectedPeriod {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        }

        periodEntries = allEntries.filter { $0.date >= startDate }
            .sorted { $0.date < $1.date } // Oldest first for graph
    }

    // MARK: - Averages

    private func computeAverages() {
        guard !periodEntries.isEmpty else {
            averageOil = 0; averageDryness = 0; averageRedness = 0; averageAcne = 0
            return
        }
        let count = Double(periodEntries.count)
        averageOil     = periodEntries.reduce(0.0) { $0 + Double($1.oilLevel) } / count
        averageDryness = periodEntries.reduce(0.0) { $0 + Double($1.drynessLevel) } / count
        averageRedness = periodEntries.reduce(0.0) { $0 + Double($1.rednessLevel) } / count
        averageAcne    = periodEntries.reduce(0.0) { $0 + Double($1.acneCount) } / count
    }

    // MARK: - Entry Operations

    func deleteEntry(at index: Int) {
        // Index in allEntries (descending)
        guard index < allEntries.count else { return }
        let entry = allEntries[index]
        // Delete associated image
        if let photoName = entry.photoFileName {
            try? dataManager.deleteImage(named: photoName)
        }
        trackerManager.deleteEntry(byId: entry.id)
        refresh()
    }
    
    func deleteEntry(at offsets: IndexSet) {
        offsets.forEach { index in
            guard index < allEntries.count else { return }
            let entry = allEntries[index]
            if let photoName = entry.photoFileName {
                try? dataManager.deleteImage(named: photoName)
            }
            trackerManager.deleteEntry(byId: entry.id)
        }
        refresh()
    }

    func savePhoto(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let name = "skin_\(UUID().uuidString).jpg"
        return try? dataManager.saveImage(data, withName: name)
    }

    func loadPhoto(named name: String) -> UIImage? {
        guard let data = dataManager.loadImage(named: name) else { return nil }
        return UIImage(data: data)
    }
}
