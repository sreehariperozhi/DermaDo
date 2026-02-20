import SwiftUI
import Combine

// MARK: - RoutinesViewModel
/// ViewModel for the routine list screen.
/// Manages fetching, toggling, and deleting routines.
class RoutinesViewModel: ObservableObject {

    // MARK: - Dependencies

    let routineManager: RoutineManagerProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State

    @Published var routines: [Routine] = []

    // MARK: - Initialization

    init(routineManager: RoutineManagerProtocol) {
        self.routineManager = routineManager
        
        // Bind to manager's data
        routineManager.routinesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoutines in
                self?.routines = newRoutines.sorted { $0.createdAt > $1.createdAt }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Operations
    
    // refresh() is no longer needed to pull data manually, 
    // but the View might call it if we kept the pull-to-refresh UI.
    // We'll keep it as a no-op or just trigger a fetch if the architecture allows.
    // For now, since the Manager is reactive, we don't strictly need it.
    func refresh() {
        // No-op or trigger manager reload if manager supports it.
    }

    func deleteRoutine(at index: Int) {
        guard index < routines.count else { return }
        let routine = routines[index]
        routineManager.deleteRoutine(byId: routine.id)
    }
    
    func deleteRoutine(at offsets: IndexSet) {
        offsets.forEach { index in
            guard index < routines.count else { return }
            let routine = routines[index]
            routineManager.deleteRoutine(byId: routine.id)
        }
    }

    func toggleRoutine(_ routine: Routine) {
        guard routines.firstIndex(where: { $0.id == routine.id }) != nil else { return }
        var updated = routine
        updated.isEnabled.toggle()
        updated.updatedAt = Date()
        
        routineManager.saveRoutine(updated)
    }
}
