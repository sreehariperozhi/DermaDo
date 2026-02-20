import Foundation
import Combine

// MARK: - InsightManagerProtocol
/// Defines the contract for generating and managing skincare insights.
protocol InsightManagerProtocol: AnyObject {
    var insightsPublisher: AnyPublisher<[Insight], Never> { get }
    
    func fetchAllInsights() -> [Insight]
    func fetchInsight(byId id: UUID) -> Insight?
    func generateInsights() -> [Insight]
}
