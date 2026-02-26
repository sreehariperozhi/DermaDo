import SwiftUI

struct RoutineDetailView: View {
    @StateObject var viewModel: RoutineDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dependencies: AppDependencies
    @EnvironmentObject var activeSession: ActiveRoutineSession
    @EnvironmentObject var voiceManager: VoiceManager

    @State private var showingStepPicker = false
    @State private var showingLayerWarning = false
    @State private var stepToEdit: RoutineStep?
    @State private var showingRoutineSession = false

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

                    // MARK: - Routine Time Section
                    Section(header: sectionHeader("Routine Time")) {
                        Toggle("Reminders", isOn: $viewModel.notifyReminder)
                            .tint(DesignColors.roseGold)
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        if viewModel.notifyReminder {
                            DatePicker("Trigger At", selection: $viewModel.reminderTime, displayedComponents: .hourAndMinute)
                                .font(DesignTypography.bodyUI)
                                .foregroundColor(DesignColors.luminousPearl)
                        }
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

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(step.instruction.isEmpty ? step.stepType.rawValue.capitalized : step.instruction)
                                            .font(DesignTypography.bodyUI)
                                            .foregroundColor(DesignColors.luminousPearl)

                                        HStack(spacing: DesignSpacing.small) {
                                            if let productId = step.productId,
                                               let product = dependencies.productManager.fetchProduct(byId: productId) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: product.category.icon)
                                                        .font(.system(size: 10))
                                                    Text(product.name)
                                                        .font(.system(size: 10, weight: .medium))
                                                }
                                                .foregroundColor(DesignColors.roseGold)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(DesignColors.roseGold.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                            }
                                            
                                            // Repeat Days Label
                                            if step.repeatDays.count < 7 && !step.repeatDays.isEmpty {
                                                Text(formattedDays(step.repeatDays))
                                                    .font(DesignTypography.microUI)
                                                    .captionTracking()
                                                    .foregroundColor(DesignColors.liquidSilver.opacity(0.6))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(DesignColors.voidAsh.opacity(0.3))
                                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                            }
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

                    // MARK: - Start Routine (Edit mode only)
                    if case .edit(_) = viewModel.mode {
                        Section {
                            Button(action: {
                                showingRoutineSession = true
                            }) {
                                HStack {
                                    Spacer()
                                    if viewModel.isEnabled {
                                        Image(systemName: "play.fill")
                                        Text("Start Routine")
                                            .fontWeight(.semibold)
                                    } else {
                                        Image(systemName: "pause.circle")
                                        Text("Routine is paused")
                                    }
                                    Spacer()
                                }
                                .font(DesignTypography.bodyStrongUI)
                                .foregroundColor(viewModel.isEnabled ? DesignColors.voidObsidian : DesignColors.liquidSilver)
                                .padding(.vertical, DesignSpacing.standard)
                            }
                            .disabled(!viewModel.isEnabled)
                            .listRowBackground(
                                viewModel.isEnabled
                                    ? DesignColors.luminousPearl
                                    : DesignColors.voidAsh.opacity(0.5)
                            )
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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
                .fullScreenCover(isPresented: $showingRoutineSession) {
                    if case .edit(let routine) = viewModel.mode {
                        RoutineSessionView2(
                            routine: routine,
                            productManager: dependencies.productManager,
                            progressManager: dependencies.progressManager,
                            trackerManager: dependencies.trackerManager,
                            activeSession: activeSession,
                            voiceManager: voiceManager
                        )
                    }
                }

                // Toast Overlay
                if let message = viewModel.orderViolationMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(DesignColors.roseGold)
                            Text(message)
                                .font(DesignTypography.captionUI)
                                .foregroundColor(DesignColors.luminousPearl)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(DesignColors.voidAsh.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.orderViolationMessage)
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

    private func formattedDays(_ days: [DayOfWeek]) -> String {
        if days.count == 7 { return "Daily" }
        if days.isEmpty { return "Never" }
        
        let sortedDays = days.sorted { d1, d2 in
            (DayOfWeek.allCases.firstIndex(of: d1) ?? 0) < (DayOfWeek.allCases.firstIndex(of: d2) ?? 0)
        }
        
        return sortedDays.map { day in
            switch day {
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            case .sunday: return "Sun"
            }
        }.joined(separator: ", ")
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
