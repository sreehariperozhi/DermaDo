import Foundation
import Combine

// MARK: - ProductManager
/// Manages the skincare product catalog using DataManager for persistence.
final class ProductManager: ProductManagerProtocol, ObservableObject {

    // MARK: - Dependencies

    private let dataManager: DataManagerProtocol
    private let notificationManager: NotificationManagerProtocol
    
    // MARK: - Published State
    
    @Published private(set) var products: [Product] = []
    
    var productsPublisher: AnyPublisher<[Product], Never> {
        $products.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        dataManager: DataManagerProtocol = DataManager(),
        notificationManager: NotificationManagerProtocol
    ) {
        self.dataManager = dataManager
        self.notificationManager = notificationManager
        
        loadProducts()
        setupDetailedObservations()
    }
    
    private func setupDetailedObservations() {
        dataManager.dataChanged
            .filter { $0 == DataManager.StorageKey.products }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadProducts()
            }
            .store(in: &cancellables)
    }
    
    private func loadProducts() {
        self.products = dataManager.loadCollection(forKey: DataManager.StorageKey.products, as: Product.self)
    }

    // MARK: - ProductManagerProtocol

    func fetchAllProducts() -> [Product] {
        return products
    }

    func fetchProduct(byId id: UUID) -> Product? {
        return products.first { $0.id == id }
    }

    func saveProduct(_ product: Product) {
        var currentProducts = products
        if let index = currentProducts.firstIndex(where: { $0.id == product.id }) {
            currentProducts[index] = product
        } else {
            currentProducts.append(product)
        }
        
        // Optimistic update
        self.products = currentProducts
        
        // Persist
        try? dataManager.saveCollection(currentProducts, forKey: DataManager.StorageKey.products)
        
        notificationManager.scheduleExpiryReminder(product)
    }

    func deleteProduct(byId id: UUID) {
        guard let product = products.first(where: { $0.id == id }) else { return }
        
        var currentProducts = products
        currentProducts.removeAll { $0.id == id }
        
        // Optimistic update
        self.products = currentProducts
        
        // Persist
        try? dataManager.saveCollection(currentProducts, forKey: DataManager.StorageKey.products)
        notificationManager.cancelProductExpiry(product)
        
        // Cleanup image if exists
        if let imageFileName = product.imageFileName {
            try? dataManager.deleteImage(named: imageFileName)
        }
    }
    
    // MARK: - Images
    
    func saveProductImage(_ data: Data) -> String? {
        let fileName = "product_\(UUID().uuidString).jpg"
        do {
            return try dataManager.saveImage(data, withName: fileName)
        } catch {
            print("Failed to save product image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func fetchProductImage(named name: String) -> Data? {
        return dataManager.loadImage(named: name)
    }
}
