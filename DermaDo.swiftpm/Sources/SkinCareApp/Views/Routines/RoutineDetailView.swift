import SwiftUI

struct RoutineDetailView: View {
    @StateObject var viewModel: RoutineDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dependencies: AppDependencies

    @State private var showingStepPicker = false
    @State private var showingLayerWarning = false
    @State private var stepToEdit: RoutineStep?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    TextField("Routine Name", text: $viewModel.name)

                    Picker("Time of Day", selection: $viewModel.timeOfDay) {
                        Label("Morning", systemImage: "sun.max").tag(TimeOfDay.morning)
                        Label("Evening", systemImage: "moon.stars").tag(TimeOfDay.evening)
                        Label("Both", systemImage: "clock").tag(TimeOfDay.both)
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Toggle("Enabled", isOn: $viewModel.isEnabled)
                        .tint(.appAccentPrimary)
                }

                Section(header: Text("Repeat Days").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    DayPickerView(selectedDays: $viewModel.repeatDays)
                        .frame(height: 60)
                }

                Section(header: Text("Steps").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                        Button(action: {
                            stepToEdit = step
                        }) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.appAccentSubtle)
                                        .frame(width: 26, height: 26)

                                    Text("\(index + 1)")
                                        .font(.appNumericSmall)
                                        .foregroundColor(.appAccentPrimary)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.instruction)
                                        .font(.appBody)
                                        .foregroundColor(.appTextPrimary)

                                    if let productId = step.productId,
                                       let product = dependencies.productManager.fetchProduct(byId: productId) {
                                        HStack(spacing: 4) {
                                            Image(systemName: product.category.icon)
                                                .font(.system(size: 10))
                                                .symbolRenderingMode(.hierarchical)
                                            Text(product.name)
                                                .font(.system(size: 12, weight: .medium))
                                        }
                                        .foregroundColor(.appAccentPrimary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.appAccentSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                    }
                                }

                                Spacer()

                                if let duration = step.durationSeconds {
                                    Text("\(duration)s")
                                        .font(.appCaptionText)
                                        .foregroundColor(.appTextSecondary)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.appTextTertiary)
                                    .padding(.leading, 4)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: viewModel.removeStep)
                    .onMove(perform: viewModel.moveStep)

                    Button(action: { showingStepPicker = true }) {
                        Label("Add Step", systemImage: "plus.circle")
                            .foregroundColor(.appAccentPrimary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle(viewModel.modeTitle)
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
                        let result = viewModel.checkValidation()
                        if !result.isValid {
                            showingLayerWarning = true
                        } else {
                            viewModel.save()
                        }
                    }
                    .foregroundColor(.appAccentPrimary)
                }
            }
            .confirmationDialog("Choose a step type", isPresented: $showingStepPicker, titleVisibility: .visible) {
                Button("Cleanser") { viewModel.addStep(type: .cleanse) }
                Button("Exfoliant") { viewModel.addStep(type: .exfoliate) }
                Button("Toner") { viewModel.addStep(type: .tone) }
                Button("Serum / Treatment") { viewModel.addStep(type: .treat) }
                Button("Mask") { viewModel.addStep(type: .mask) }
                Button("Moisturizer") { viewModel.addStep(type: .moisturize) }
                Button("Sunscreen") { viewModel.addStep(type: .protect) }
                Button("Cancel", role: .cancel) { }
            }
            .alert(isPresented: $showingLayerWarning) {
                Alert(
                    title: Text("Layer Order Warning"),
                    message: Text(viewModel.validate().message),
                    primaryButton: .default(Text("Auto-Fix")) {
                        viewModel.autoFixOrder()
                    },
                    secondaryButton: .destructive(Text("Save Anyway")) {
                        viewModel.save()
                    }
                )
            }
            .sheet(item: $stepToEdit) { step in
                EditRoutineStepView(
                    step: step,
                    onSave: { updatedStep in
                        viewModel.updateStep(updatedStep)
                    },
                    onDelete: { id in
                        viewModel.deleteStep(id: id)
                    }
                )
                .environmentObject(dependencies)
            }
            .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

extension RoutineDetailViewModel {
    var modeTitle: String {
        switch mode {
        case .add: return "New Routine"
        case .edit: return "Edit Routine"
        }
    }
}
