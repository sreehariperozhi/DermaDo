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
    
    init(routine: Routine, productManager: ProductManagerProtocol, activeSession: ActiveRoutineSession? = nil) {
        self.routine = routine
        self.productManager = productManager
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
        withAnimation(DesignMotion.heroMaterialize) {
            activeSession?.currentStep = .none
            activeSession?.progressPercentage = 1.0
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
