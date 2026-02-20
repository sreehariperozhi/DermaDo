import SwiftUI
import Combine

// MARK: - ProductsViewModel
/// ViewModel for the Products tab.
/// Groups products by category, supports search, and matches products to routines.
class ProductsViewModel: ObservableObject {

    // MARK: - Dependencies

    let productManager: ProductManagerProtocol
    let routineManager: RoutineManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var products: [Product] = []
    @Published var routines: [Routine] = []
    @Published var searchText: String = ""

    // MARK: - Initialization

    init(productManager: ProductManagerProtocol, routineManager: RoutineManagerProtocol) {
        self.productManager = productManager
        self.routineManager = routineManager

        productManager.productsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newProducts in
                self?.products = newProducts.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            }
            .store(in: &cancellables)

        routineManager.routinesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoutines in
                self?.routines = newRoutines
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed

    /// Products filtered by the current search text.
    var filteredProducts: [Product] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return products
        }
        let query = searchText.lowercased()
        return products.filter {
            $0.name.lowercased().contains(query)
            || $0.brand.lowercased().contains(query)
            || $0.category.displayName.lowercased().contains(query)
        }
    }

    /// Active categories that have at least one product (respecting current filter).
    var activeCategories: [ProductCategory] {
        let cats = Set(filteredProducts.map(\.category))
        return ProductCategory.allCases.filter { cats.contains($0) }
    }

    /// Products in a given category (respecting current filter).
    func products(in category: ProductCategory) -> [Product] {
        filteredProducts.filter { $0.category == category }
    }

    /// Routines whose steps reference the given product.
    func routines(for product: Product) -> [Routine] {
        routines.filter { routine in
            routine.steps.contains { $0.productId == product.id }
        }
    }

    // MARK: - Actions

    func deleteProduct(_ product: Product) {
        productManager.deleteProduct(byId: product.id)
    }

    func deleteProducts(at offsets: IndexSet, in category: ProductCategory) {
        let categoryProducts = products(in: category)
        offsets.forEach { index in
            guard index < categoryProducts.count else { return }
            productManager.deleteProduct(byId: categoryProducts[index].id)
        }
    }
}
