import SwiftUI

struct EditRoutineStepView: View {
    @Environment(\.presentationMode) var presentationMode

    @State var step: RoutineStep
    var onSave: (RoutineStep) -> Void
    var onDelete: (UUID) -> Void

    // For duration picking
    let durationOptions = [0, 30, 60, 120, 300, 600]

    // Frequency Binding Helper
    private var frequencyBinding: Binding<Bool> {
        Binding(
            get: { step.repeatDays.count == 7 },
            set: { isDaily in
                if isDaily {
                    step.repeatDays = DayOfWeek.allCases
                } else {
                    // Default to current day if moving from daily
                    if step.repeatDays.count == 7 {
                        step.repeatDays = [currentDay]
                    }
                }
            }
        )
    }

    // Days Binding Helper
    private var daysBinding: Binding<Set<DayOfWeek>> {
        Binding(
            get: { Set(step.repeatDays) },
            set: { step.repeatDays = Array($0) }
        )
    }

    private var currentDay: DayOfWeek {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }

    var body: some View {
        NavigationView {
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

                    // MARK: - Repeat Options Section
                    Section(header: sectionHeader("Repeat Options")) {
                        Picker("Frequency", selection: frequencyBinding) {
                            Text("Daily").tag(true)
                            Text("Specific Days").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if step.repeatDays.count < 7 {
                            DayPickerView(selectedDays: daysBinding)
                                .padding(.vertical, DesignSpacing.small)
                        }
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
                        }
                    }
                    .listRowBackground(Color.red.opacity(0.08))
                }
                .scrollContentBackground(.hidden)
            }
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
