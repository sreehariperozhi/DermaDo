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
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle("Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.appAccentPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave(step)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.appAccentPrimary)
                }
            }
            // Auto fill instruction when type changes, but only if user hasn't heavily customized it (optional simple sync)
            .onChange(of: step.stepType) { newType in
                // If it looks like a default name, update it automatically
                if StepType.allCases.contains(where: { RoutineValidationEngine.displayName($0) == step.instruction }) {
                    step.instruction = RoutineValidationEngine.displayName(newType)
                }
            }
        }
    }
}
