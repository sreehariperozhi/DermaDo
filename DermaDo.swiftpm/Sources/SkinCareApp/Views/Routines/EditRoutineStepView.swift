import SwiftUI

struct EditRoutineStepView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var step: RoutineStep
    var onSave: (RoutineStep) -> Void
    var onDelete: (UUID) -> Void

    // For duration picking
    let durationOptions = [0, 30, 60, 120, 300, 600]

    var body: some View {
        NavigationView {
<<<<<<< HEAD
            Form {
                Section(header: Text("Step Details").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Picker("Type", selection: $step.stepType) {
                        ForEach(StepType.allCases, id: \.self) { type in
                            Text(RoutineValidationEngine.displayName(type)).tag(type)
                        }
                    }
                    
                    TextField("Instruction", text: $step.instruction)
                }
                
                Section(header: Text("Duration").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Picker("Specific Duration (Seconds)", selection: Binding(
                        get: { step.durationSeconds ?? 0 },
                        set: { step.durationSeconds = $0 == 0 ? nil : $0 }
                    )) {
                        Text("None").tag(0)
                        ForEach(durationOptions.filter { $0 > 0 }, id: \.self) { duration in
                            Text("\(duration)s").tag(duration)
                        }
                    }
                }

                Section(header: Text("Repeat Options").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Picker("Frequency", selection: Binding(
                        get: { step.repeatDays.count == 7 ? "daily" : "specific" },
                        set: { newValue in
                            if newValue == "daily" {
                                step.repeatDays = DayOfWeek.allCases
                            }
                        }
                    )) {
                        Text("Daily").tag("daily")
                        Text("Specific Days").tag("specific")
                    }
                    .pickerStyle(.segmented)

                    if step.repeatDays.count < 7 || true { // Always show if we want custom toggling
                        DayPickerView(selectedDays: Binding(
                            get: { Set(step.repeatDays) },
                            set: { step.repeatDays = Array($0).sorted { d1, d2 in
                                (DayOfWeek.allCases.firstIndex(of: d1) ?? 0) < (DayOfWeek.allCases.firstIndex(of: d2) ?? 0)
                            }}
                        ))
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        onDelete(step.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Delete Step")
                            Spacer()
=======
            ZStack {
                DesignColors.voidObsidian.ignoresSafeArea()

                Form {
                    Section(header: sectionHeader("Step Details")) {
                        Picker("Type", selection: $step.stepType) {
                            ForEach(StepType.allCases, id: \.self) { type in
                                Text(RoutineValidationEngine.displayName(type)).tag(type)
                            }
                        }
                        .foregroundColor(DesignColors.luminousPearl)

                        TextField("Instruction", text: $step.instruction)
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.luminousPearl)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section(header: sectionHeader("Duration")) {
                        Picker("Specific Duration (Seconds)", selection: Binding(
                            get: { step.durationSeconds ?? 0 },
                            set: { step.durationSeconds = $0 == 0 ? nil : $0 }
                        )) {
                            Text("None").tag(0)
                            ForEach(durationOptions.filter { $0 > 0 }, id: \.self) { duration in
                                Text("\(duration)s").tag(duration)
                            }
                        }
                        .foregroundColor(DesignColors.luminousPearl)
                    }
                    .listRowBackground(Color.white.opacity(0.05))

                    Section {
                        Button(role: .destructive, action: {
                            onDelete(step.id)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Delete Step")
                                Spacer()
                            }
>>>>>>> mac-ui-major-backup
                        }
                    }
                    .listRowBackground(Color.red.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
            }
            .colorScheme(.dark)
            .navigationTitle("Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(DesignColors.liquidSilver)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave(step)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(DesignColors.roseGold)
                    .fontWeight(.semibold)
                }
            }
            // Auto fill instruction when type changes
            .onChange(of: step.stepType) { newType in
                if StepType.allCases.contains(where: { RoutineValidationEngine.displayName($0) == step.instruction }) {
                    step.instruction = RoutineValidationEngine.displayName(newType)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.captionUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
    }
}
