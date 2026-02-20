import Foundation
import Combine

// MARK: - RoutineManagerProtocol
/// Defines the contract for managing skincare routines.
protocol RoutineManagerProtocol: AnyObject {
    var routinesPublisher: AnyPublisher<[Routine], Never> { get }
    
    func fetchAllRoutines() -> [Routine]
    func fetchRoutine(byId id: UUID) -> Routine?
    func saveRoutine(_ routine: Routine)
    func deleteRoutine(byId id: UUID)
    func rescheduleAllReminders()
}
