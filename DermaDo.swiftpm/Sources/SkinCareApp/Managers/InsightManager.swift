import Foundation
import Combine

// MARK: - InsightManager
/// Manages skincare insights using DataManager for persistence.
final class InsightManager: InsightManagerProtocol, ObservableObject {

    // MARK: - Dependencies

    private let dataManager: DataManagerProtocol
    
    // MARK: - Published State
    
    @Published private(set) var insights: [Insight] = []
    
    var insightsPublisher: AnyPublisher<[Insight], Never> {
        $insights.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(dataManager: DataManagerProtocol = DataManager()) {
        self.dataManager = dataManager
        
        loadInsights()
        setupDetailedObservations()
    }
    
    private func setupDetailedObservations() {
        // Assuming "insights" is the key. 
        // Note: StorageKey.insights doesn't exist in DataManager yet?
        // Let's check DataManager.StorageKey.
        // It wasn't in the enum in previous view_file of DataManager.swift.
        // Wait, line 32 of DataManager:
        // static let routines = "routines" ...
        // static let skinEntries = ...
        // static let achievements = ...
        // static let settings = ...
        // No insights.
        // InsightManager.swift used string "insights".
        // I should probably add it to DataManager or just use string.
        // I'll stick to string "insights" match to avoid changing DataManager again if not strictly needed,
        // but adding it to DataManager is cleaner. 
        // For now, I'll filter by string "insights".
        
        dataManager.dataChanged
            .filter { $0 == "insights" } 
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadInsights()
            }
            .store(in: &cancellables)
    }
    
    private func loadInsights() {
        self.insights = dataManager.loadCollection(forKey: "insights", as: Insight.self)
    }

    // MARK: - InsightManagerProtocol

    func fetchAllInsights() -> [Insight] {
        return insights
    }

    func fetchInsight(byId id: UUID) -> Insight? {
        return insights.first { $0.id == id }
    }

    func generateInsights() -> [Insight] {
        // TODO: Implement insight generation logic based on skin entries & routines
        return []
    }
}
