import SwiftUI

// MARK: - ProductsView
struct ProductsView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
        ProductsViewContent(
            viewModel: ProductsViewModel(
                productManager: dependencies.productManager,
                routineManager: dependencies.routineManager
            )
        )
    }
}

// MARK: - ProductsViewContent
struct ProductsViewContent: View {
    @StateObject var viewModel: ProductsViewModel
    @State private var showingAddProduct = false
    @State private var selectedProduct: Product?
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackgroundPrimary.ignoresSafeArea()

                if viewModel.products.isEmpty {
                    // MARK: - Empty State
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "bag")
                            .font(.system(size: 40))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.appTextTertiary)

                        Text("No Products Yet")
                            .font(.appSectionTitle)
                            .foregroundColor(.appTextPrimary)

                        Text("Add skincare products you own to track them and match with your routines.")
                            .font(.appBody)
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xxl)

                        Button(action: { showingAddProduct = true }) {
                            Label("Add Product", systemImage: "plus.circle")
                                .font(.appLabelLarge)
                                .foregroundColor(.white)
                                .padding(.horizontal, AppSpacing.xl)
                                .padding(.vertical, AppSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: AppSpacing.radiusSmall, style: .continuous)
                                        .fill(Color.appAccentPrimary)
                                )
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                } else {
                    // MARK: - Product List
                    List {
                        Section {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.appTextTertiary)
                                TextField("Search products...", text: $viewModel.searchText)
                                    .font(.appBody)
                            }
                        }

                        if viewModel.activeCategories.isEmpty && !viewModel.searchText.isEmpty {
                            Section {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 24))
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundColor(.appTextTertiary)
                                        Text("No products match \"\(viewModel.searchText)\"")
                                            .font(.appBody)
                                            .foregroundColor(.appTextSecondary)
                                    }
                                    .padding(.vertical, AppSpacing.xl)
                                    Spacer()
                                }
                            }
                        }

                        ForEach(viewModel.activeCategories, id: \.self) { category in
                            Section(header: categoryHeader(category)) {
                                ForEach(viewModel.products(in: category)) { product in
                                    Button(action: { selectedProduct = product }) {
                                        ProductCardView(
                                            product: product,
                                            matchedRoutines: viewModel.routines(for: product)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    viewModel.deleteProducts(at: offsets, in: category)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .opacity(appeared ? 1 : 0)
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProduct = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appAccentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddEditProductView(
                    mode: .add,
                    productManager: viewModel.productManager,
                    routineManager: viewModel.routineManager
                )
            }
            .sheet(item: $selectedProduct) { product in
                AddEditProductView(
                    mode: .edit(product),
                    productManager: viewModel.productManager,
                    routineManager: viewModel.routineManager
                )
            }
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appeared = true
                    }
                } else {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func categoryHeader(_ category: ProductCategory) -> some View {
        HStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.system(size: 13, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.appAccentPrimary)
            Text(category.displayName)
                .font(.appLabelLarge)
                .foregroundColor(.appTextPrimary)

            Spacer()

            Text("\(viewModel.products(in: category).count)")
                .font(.appCaptionText)
                .foregroundColor(.appTextSecondary)
        }
    }
}
