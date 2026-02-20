import SwiftUI
import PhotosUI

// MARK: - AddEditProductView
struct AddEditProductView: View {
    @Environment(\.presentationMode) var presentationMode

    enum Mode {
        case add
        case edit(Product)
    }

    let mode: Mode
    let productManager: ProductManagerProtocol
    let routineManager: RoutineManagerProtocol

    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var category: ProductCategory = .other
    @State private var notes: String = ""
    @State private var showValidation = false

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var originalImageFileName: String?

    private var existingProduct: Product? {
        if case .edit(let product) = mode { return product }
        return nil
    }

    private var navigationTitle: String {
        existingProduct != nil ? "Edit Product" : "Add Product"
    }

    private var autoMatchedRoutines: [Routine] {
        let targetStepType = stepType(for: category)
        return routineManager.fetchAllRoutines().filter { routine in
            routine.steps.contains { $0.stepType == targetStepType }
        }
    }

    init(mode: Mode, productManager: ProductManagerProtocol, routineManager: RoutineManagerProtocol) {
        self.mode = mode
        self.productManager = productManager
        self.routineManager = routineManager

        if case .edit(let product) = mode {
            _name = State(initialValue: product.name)
            _brand = State(initialValue: product.brand)
            _category = State(initialValue: product.category)
            _notes = State(initialValue: product.notes ?? "")
            _originalImageFileName = State(initialValue: product.imageFileName)
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Product Photo
                Section(header: Text("Photo").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.appBackgroundSecondary)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)

                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 28))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appTextTertiary)
                                Text("Add Product Photo")
                                    .font(.appBody)
                                    .foregroundColor(.appTextTertiary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottomTrailing) {
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            Image(systemName: "pencil.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.appAccentPrimary)
                                .font(.system(size: 28))
                                .background(
                                    Circle()
                                        .fill(Color.appCardBackground)
                                )
                                .padding(8)
                        }
                    }
                }
                .listRowBackground(Color.clear)

                // MARK: - Product Details
                Section(header: Text("Product Details").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    TextField("Product Name", text: $name)
                        .font(.appBody)
                    TextField("Brand", text: $brand)
                        .font(.appBody)

                    Picker("Category", selection: $category) {
                        ForEach(ProductCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                // MARK: - Notes
                Section(header: Text("Notes").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .font(.appBody)
                }

                // MARK: - Auto-Linked Routines Preview
                Section(header: Text("Auto-Linked Routines").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    if autoMatchedRoutines.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.appTextTertiary)
                            Text("No routines have a \(stepType(for: category).rawValue) step yet. Create one in Routines to auto-link.")
                                .font(.appCaptionText)
                                .foregroundColor(.appTextTertiary)
                        }
                    } else {
                        ForEach(autoMatchedRoutines) { routine in
                            HStack(spacing: 10) {
                                Image(systemName: routine.timeOfDay == .morning ? "sun.max" : routine.timeOfDay == .evening ? "moon.stars" : "clock")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appAccentPrimary)
                                    .font(.system(size: 14))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(routine.name)
                                        .font(.appBody)
                                        .foregroundColor(.appTextPrimary)

                                    Text("Has \(stepType(for: category).rawValue) step — will auto-link")
                                        .font(.appCaptionText)
                                        .foregroundColor(.appSuccess)
                                }

                                Spacer()

                                Image(systemName: "link.circle.fill")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appSuccess)
                                    .font(.system(size: 18))
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.appAccentPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .foregroundColor(.appAccentPrimary)
                }
            }
            .alert("Missing Information", isPresented: $showValidation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a product name.")
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
            .onAppear {
                if let fileName = originalImageFileName, selectedImage == nil {
                    if let data = productManager.fetchProductImage(named: fileName),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func saveProduct() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showValidation = true
            return
        }

        var finalImageFileName: String? = originalImageFileName

        if let newImage = selectedImage {
            if selectedItem != nil {
                if let data = newImage.jpegData(compressionQuality: 0.8) {
                    if let newName = productManager.saveProductImage(data) {
                        finalImageFileName = newName
                    }
                }
            }
        }

        let matchingStepType = stepType(for: category)
        let allRoutines = routineManager.fetchAllRoutines()
        var linkedRoutineIds: [UUID] = []

        let productId = existingProduct?.id ?? UUID()

        let product = Product(
            id: productId,
            name: trimmedName,
            brand: brand.trimmingCharacters(in: .whitespaces),
            category: category,
            ingredients: existingProduct?.ingredients ?? [],
            openedDate: existingProduct?.openedDate,
            expiryDate: existingProduct?.expiryDate,
            imageFileName: finalImageFileName,
            linkedRoutineIds: [],
            notes: notes.isEmpty ? nil : notes,
            rating: existingProduct?.rating,
            isFavorite: existingProduct?.isFavorite ?? false,
            createdAt: existingProduct?.createdAt ?? Date(),
            updatedAt: Date()
        )

        for routine in allRoutines {
            var updatedSteps = routine.steps
            var didUpdate = false

            for i in updatedSteps.indices {
                if updatedSteps[i].stepType == matchingStepType && updatedSteps[i].productId == nil {
                    updatedSteps[i] = RoutineStep(
                        id: updatedSteps[i].id,
                        order: updatedSteps[i].order,
                        productId: productId,
                        stepType: updatedSteps[i].stepType,
                        instruction: updatedSteps[i].instruction,
                        durationSeconds: updatedSteps[i].durationSeconds,
                        createdAt: updatedSteps[i].createdAt,
                        updatedAt: Date()
                    )
                    didUpdate = true
                }
            }

            if didUpdate {
                linkedRoutineIds.append(routine.id)
                let updatedRoutine = Routine(
                    id: routine.id,
                    name: routine.name,
                    timeOfDay: routine.timeOfDay,
                    steps: updatedSteps,
                    repeatDays: routine.repeatDays,
                    isEnabled: routine.isEnabled,
                    notifyReminder: routine.notifyReminder,
                    reminderTime: routine.reminderTime,
                    createdAt: routine.createdAt,
                    updatedAt: Date()
                )
                routineManager.saveRoutine(updatedRoutine)
            }
        }

        let finalProduct = Product(
            id: productId,
            name: product.name,
            brand: product.brand,
            category: product.category,
            ingredients: product.ingredients,
            openedDate: product.openedDate,
            expiryDate: product.expiryDate,
            imageFileName: product.imageFileName,
            linkedRoutineIds: linkedRoutineIds,
            notes: product.notes,
            rating: product.rating,
            isFavorite: product.isFavorite,
            createdAt: product.createdAt,
            updatedAt: Date()
        )
        productManager.saveProduct(finalProduct)

        presentationMode.wrappedValue.dismiss()
    }

    private func stepType(for category: ProductCategory) -> StepType {
        switch category {
        case .cleanser:    return .cleanse
        case .toner:       return .tone
        case .serum:       return .treat
        case .moisturizer: return .moisturize
        case .sunscreen:   return .protect
        case .mask:        return .mask
        case .exfoliant:   return .exfoliate
        default:           return .apply
        }
    }
}
