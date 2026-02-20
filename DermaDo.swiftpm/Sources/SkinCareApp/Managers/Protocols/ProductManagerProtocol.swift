import Foundation
import Combine

// MARK: - ProductManagerProtocol
/// Defines the contract for managing the product catalog.
protocol ProductManagerProtocol: AnyObject {
    var productsPublisher: AnyPublisher<[Product], Never> { get }
    
    func fetchAllProducts() -> [Product]
    func fetchProduct(byId id: UUID) -> Product?
    func saveProduct(_ product: Product)
    func deleteProduct(byId id: UUID)

    // MARK: - Images
    func saveProductImage(_ data: Data) -> String?
    func fetchProductImage(named name: String) -> Data?
}
