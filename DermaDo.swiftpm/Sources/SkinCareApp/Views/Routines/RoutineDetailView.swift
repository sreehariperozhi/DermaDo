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
            ZStack {
                // Void background
                DesignColors.voidObsidian.ignoresSafeArea()

                Form {
                    // MARK: - Details Section
                    Section(header: sectionHeader("Details")) {
                        TextField("Routine Name", text: $viewModel.name)
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.luminousPearl)

                        Picker("Time of Day", selection: $viewModel.timeOfDay) {
                            Label("Morning", systemImage: "sun.max").tag(TimeOfDay.morning)
                            Label("Evening", systemImage: "moon.stars").tag(TimeOfDay.evening)
                            Label("Both", systemImage: "clock").tag(TimeOfDay.both)
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Toggle("Enabled", isOn: $viewModel.isEnabled)
                            .tint(DesignColors.roseGold)
                            .foregroundColor(DesignColors.luminousPearl)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Repeat Days Section
                    Section(header: sectionHeader("Repeat Days")) {
                        DayPickerView(selectedDays: $viewModel.repeatDays)
                            .frame(height: 60)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    // MARK: - Steps Section
                    Section(header: sectionHeader("Steps")) {
                        ForEach(Array(viewModel.steps.enumerated()), id: \.element.id) { index, step in
                            Button(action: {
                                stepToEdit = step
                            }) {
                                HStack {
                                    // Step number badge
                                    ZStack {
                                        Circle()
                                            .fill(DesignColors.roseGold.opacity(0.15))
                                            .frame(width: 28, height: 28)

                                        Text("\(index + 1)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(DesignColors.roseGold)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(step.instruction.isEmpty ? step.stepType.rawValue.capitalized : step.instruction)
                                            .font(DesignTypography.bodyUI)
                                            .foregroundColor(DesignColors.luminousPearl)

                                        if let productId = step.productId,
                                           let product = dependencies.productManager.fetchProduct(byId: productId) {
                                            HStack(spacing: 4) {
                                                Image(systemName: product.category.icon)
                                                    .font(.system(size: 10))
                                                Text(product.name)
                                                    .font(.system(size: 12, weight: .medium))
                                            }
                                            .foregroundColor(DesignColors.roseGold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(DesignColors.roseGold.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                        }
                                    }

                                    Spacer()

                                    if let duration = step.durationSeconds {
                                        Text("\(duration)s")
                                            .font(DesignTypography.captionUI)
                                            .foregroundColor(DesignColors.liquidSilver)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(DesignColors.liquidSilver.opacity(0.4))
                                        .padding(.leading, 4)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: viewModel.removeStep)
                        .onMove(perform: viewModel.moveStep)

                        Button(action: { showingStepPicker = true }) {
                            HStack(spacing: DesignSpacing.small) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(DesignColors.roseGold)
                                Text("Add Step")
                                    .foregroundColor(DesignColors.roseGold)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }
                .scrollContentBackground(.hidden)
            }
            .colorScheme(.dark)
            .navigationTitle(viewModel.modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(DesignColors.liquidSilver)
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
                    .foregroundColor(DesignColors.roseGold)
                    .fontWeight(.semibold)
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

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.captionUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
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
