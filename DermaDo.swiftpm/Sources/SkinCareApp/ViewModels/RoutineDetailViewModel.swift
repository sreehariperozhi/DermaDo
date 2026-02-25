import SwiftUI
import Combine

// MARK: - RoutineDetailViewModel
/// ViewModel for the add / edit routine form.
/// Holds mutable draft state and validates before saving.
class RoutineDetailViewModel: ObservableObject {

    // MARK: - Dependencies

    private let routineManager: RoutineManagerProtocol

    // MARK: - Mode

    enum Mode { case add, edit(Routine) }
    let mode: Mode

    // MARK: - Published Draft State

    @Published var name: String
    @Published var timeOfDay: TimeOfDay
    @Published var repeatDays: Set<DayOfWeek>
    @Published var isEnabled: Bool
    @Published var notifyReminder: Bool
    @Published var reminderTime: Date
    @Published var steps: [RoutineStep]
    @Published var showValidationAlert: Bool = false
    @Published var validationMessage: String = ""
    @Published var orderViolationMessage: String? = nil
    @Published var shouldDismiss: Bool = false

    private let existingId: UUID?
    private let existingCreatedAt: Date

    // MARK: - Initialization

    init(routineManager: RoutineManagerProtocol, mode: Mode) {
        self.routineManager = routineManager
        self.mode = mode
        
        switch mode {
        case .add:
            existingId = nil
            existingCreatedAt = Date()
            name = ""
            timeOfDay = .morning
            repeatDays = Set(DayOfWeek.allCases)
            isEnabled = true
            notifyReminder = true // Default to true when adding
            reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
            steps = []

        case .edit(let routine):
            existingId = routine.id
            existingCreatedAt = routine.createdAt
            name = routine.name
            timeOfDay = routine.timeOfDay
            repeatDays = Set(routine.repeatDays)
            isEnabled = routine.isEnabled
            notifyReminder = routine.notifyReminder
            reminderTime = routine.reminderTime ?? Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
            steps = routine.steps.sorted { $0.order < $1.order }
        }
        
        // Setup initial state
        self.name = name 
        self.timeOfDay = timeOfDay
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.notifyReminder = notifyReminder
        self.reminderTime = reminderTime
        self.steps = steps
    }

    // MARK: - Step Management

    func addStep(type: StepType, instruction: String = "", duration: Int? = nil) {
        let step = RoutineStep(
            order: steps.count,
            stepType: type,
            instruction: instruction.isEmpty ? RoutineValidationEngine.displayName(type) : instruction,
            durationSeconds: duration
        )
        steps.append(step)
    }

    func removeStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
        renumberSteps()
    }
    
    func moveStep(from source: IndexSet, to destination: Int) {
        steps.move(fromOffsets: source, toOffset: destination)
        renumberSteps()
        
        // Validation check for reorder
        let result = validate()
        if !result.isValid, let firstViolation = result.violations.first {
            // Pick a friendly message
            let typeName = RoutineValidationEngine.displayName(firstViolation.stepType)
            let beforeName = RoutineValidationEngine.displayName(firstViolation.shouldComeBefore)
            orderViolationMessage = "\(typeName) usually comes before \(beforeName)."
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation {
                    self?.orderViolationMessage = nil
                }
            }
        }
    }

    func updateStepDuration(at index: Int, seconds: Int?) {
        guard index < steps.count else { return }
        var step = steps[index]
        step.durationSeconds = seconds
        step.updatedAt = Date()
        steps[index] = step
    }

    func updateStep(_ updatedStep: RoutineStep) {
        if let index = steps.firstIndex(where: { $0.id == updatedStep.id }) {
            steps[index] = updatedStep
            steps[index].updatedAt = Date()
        }
    }

    func deleteStep(id: UUID) {
        steps.removeAll { $0.id == id }
        renumberSteps()
    }

    // MARK: - Validation

    func validate() -> RoutineValidationEngine.ValidationResult {
        return RoutineValidationEngine.validate(steps: steps)
    }

    func autoFixOrder() {
        steps = RoutineValidationEngine.suggestedOrder(for: steps)
    }

    var isFormValid: Bool {
        return !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !repeatDays.isEmpty
    }

    // MARK: - Save

    func save() {
        guard isFormValid else {
            validationMessage = "Please enter a routine name and select at least one day."
            showValidationAlert = true
            return
        }
        
        // Validate layer order
        let result = validate()
        if !result.isValid && !showValidationAlert { 
            // If invalid and we haven't shown alert yet, show it (controlled by View calling this)
            // But here "save()" implies final action.
            // The View should call validate() first if it wants to show the specific layer warning.
            // If we are here, we force save?
            // Let's assume View handles the "Layer Order Warning" separately before calling save, OR we can return a status.
        }

        let routine = Routine(
            id: existingId ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            timeOfDay: timeOfDay,
            steps: steps,
            repeatDays: Array(repeatDays),
            isEnabled: isEnabled,
            notifyReminder: notifyReminder,
            reminderTime: reminderTime,
            createdAt: existingCreatedAt,
            updatedAt: Date()
        )
        routineManager.saveRoutine(routine)
        shouldDismiss = true
    }
    
    // Check validation for View use
    func checkValidation() -> RoutineValidationEngine.ValidationResult {
        return validate()
    }

    // MARK: - Private

    private func renumberSteps() {
        steps = steps.enumerated().map { idx, step in
            var newStep = step
            newStep.order = idx
            return newStep
        }
    }
}
