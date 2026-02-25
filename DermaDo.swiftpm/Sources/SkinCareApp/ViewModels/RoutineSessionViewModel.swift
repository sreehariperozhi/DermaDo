import Foundation
import Combine
import SwiftUI

// MARK: - RoutineSessionViewModel
/// Manages the state of an active routine session.
/// Handles timing, step progression, and product data fetching.
@MainActor
class RoutineSessionViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let routine: Routine
    private let productManager: ProductManagerProtocol
    private let progressManager: ProgressManagerProtocol
    private let trackerManager: TrackerManagerProtocol
    private weak var activeSession: ActiveRoutineSession?
    
    // MARK: - Published State
    @Published var currentStepIndex: Int = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var isTimerActive: Bool = false
    @Published var isPaused: Bool = false
    @Published var sessionComplete: Bool = false
    @Published var isTransitioning: Bool = false
    
    // Additional UI State
    @Published var currentProduct: Product?
    @Published var currentProductImage: UIImage?
    
    // MARK: - Computed Properties
    
    var currentStep: RoutineStep? {
        guard currentStepIndex < routine.steps.count else { return nil }
        return routine.steps[currentStepIndex]
    }
    
    var totalSteps: Int {
        routine.steps.count
    }
    
    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentStepIndex) / Double(totalSteps)
    }
    
    // MARK: - Initialization
    
    init(routine: Routine, productManager: ProductManagerProtocol, progressManager: ProgressManagerProtocol, trackerManager: TrackerManagerProtocol, activeSession: ActiveRoutineSession? = nil) {
        self.routine = routine
        self.productManager = productManager
        self.progressManager = progressManager
        self.trackerManager = trackerManager
        self.activeSession = activeSession
        
        loadStepData()
    }
    
    // MARK: - Step Management
    
    private func loadStepData() {
        guard let step = currentStep else {
            finishSession()
            return
        }
        
        // Reset timer
        timeRemaining = TimeInterval(step.durationSeconds ?? 60)
        isTimerActive = false
        isPaused = false
        
        // Load product details
        if let productId = step.productId, let product = productManager.fetchProduct(byId: productId) {
            self.currentProduct = product
            if let fileName = product.imageFileName,
               let data = productManager.fetchProductImage(named: fileName),
               let image = UIImage(data: data) {
                self.currentProductImage = image
            } else {
                self.currentProductImage = nil
            }
        } else {
            self.currentProduct = nil
            self.currentProductImage = nil
        }
        
        // Update Active Session state for the Avatar
        activeSession?.currentStep = RoutineStepType.mapStepType(step.stepType)
        activeSession?.progressPercentage = self.progress
    }
    
    func nextStep() {
        if currentStepIndex < totalSteps - 1 {
            transitionToStep(currentStepIndex + 1)
        } else {
            finishSession()
        }
    }
    
    func skipStep() {
        nextStep()
    }
    
    func previousStep() {
        if currentStepIndex > 0 {
            transitionToStep(currentStepIndex - 1)
        }
    }
    
    private func transitionToStep(_ newIndex: Int) {
        stopTimer()
        isTransitioning = true
        
        // Let the exit animation play before swapping data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            self.currentStepIndex = newIndex
            self.loadStepData()
            
            // Let the entry animation play
            withAnimation(DesignMotion.heroMaterialize) {
                self.isTransitioning = false
            }
        }
    }
    
    private func finishSession() {
        stopTimer()
        sessionComplete = true
        
        // Record progress in ProgressManager (streaks, total completions)
        progressManager.recordCompletion()
        
        // Link routine to today's skin entry in TrackerManager
        linkRoutineToToday()
        
        withAnimation(DesignMotion.heroMaterialize) {
            activeSession?.currentStep = .none
            activeSession?.progressPercentage = 1.0
        }
    }
    
    private func linkRoutineToToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Find today's entry or create a minimal one
        let allEntries = trackerManager.fetchAllEntries()
        if let existing = allEntries.first(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            // Already has an entry, add this routine ID if not present
            if !existing.completedRoutineIds.contains(routine.id) {
                var routineIds = existing.completedRoutineIds
                routineIds.append(routine.id)
                // Use a shadow copy to simulate mutation of immutable struct
                let newEntry = SkinEntry(
                    id: existing.id,
                    date: existing.date,
                    acneCount: existing.acneCount,
                    oilLevel: existing.oilLevel,
                    drynessLevel: existing.drynessLevel,
                    rednessLevel: existing.rednessLevel,
                    overallScore: existing.overallScore,
                    mood: existing.mood,
                    photoFileName: existing.photoFileName,
                    notes: existing.notes,
                    completedRoutineIds: routineIds,
                    createdAt: existing.createdAt,
                    updatedAt: Date()
                )
                trackerManager.saveEntry(newEntry)
            }
        } else {
            // Create a fresh entry for today with this routine completed
            let newEntry = SkinEntry(
                date: today,
                completedRoutineIds: [routine.id]
            )
            trackerManager.saveEntry(newEntry)
        }
    }
    
    // MARK: - Timer Logic
    
    func toggleTimer() {
        if isTimerActive {
            stopTimer()
            isPaused = true
        } else {
            startTimer()
            isPaused = false
        }
    }
    
    private var timerTask: Task<Void, Never>?

    private func startTimer() {
        guard !isTimerActive && timeRemaining > 0 else { return }
        isTimerActive = true
        
        timerTask = Task {
            while !Task.isCancelled && timeRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                timeRemaining -= 1
            }
            if timeRemaining <= 0 && !Task.isCancelled {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        isTimerActive = false
        timerTask?.cancel()
        timerTask = nil
    }
    
    deinit {
        timerTask?.cancel()
    }
    
    func destroy() {
        stopTimer()
    }
}
