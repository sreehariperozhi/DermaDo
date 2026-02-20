import Foundation

// MARK: - RoutineValidationEngine
/// Validates skincare routine step ordering according to dermatological
/// best-practice layering rules. Stateless — all methods are pure functions.
///
/// **Canonical order:**
/// Cleanser → Toner → Treat (Serum) → Moisturize → Protect (Sunscreen)
///
/// Steps of the same type are allowed consecutively.
/// Steps not in the canonical list (e.g., `.mask`, `.wait`) are ignored.
enum RoutineValidationEngine {

    // MARK: - Canonical Layer Order

    /// The recommended application order. Lower index = earlier in routine.
    private static let layerOrder: [StepType] = [
        .cleanse,
        .exfoliate,
        .tone,
        .treat,       // serums, actives
        .mask,
        .moisturize,
        .protect      // sunscreen — always last
    ]

    /// Quick lookup: step type → position index.
    private static let layerIndex: [StepType: Int] = {
        var map: [StepType: Int] = [:]
        for (i, type) in layerOrder.enumerated() { map[type] = i }
        return map
    }()

    // MARK: - Validation Result

    struct ValidationResult {
        let isValid: Bool
        let violations: [Violation]

        /// Human-readable summary of all violations.
        var message: String {
            guard !isValid else { return "Routine order looks great!" }
            return violations.map(\.message).joined(separator: "\n")
        }
    }

    struct Violation: Equatable {
        let stepIndex: Int          // 0-based position in the steps array
        let stepType: StepType
        let shouldComeBefore: StepType
        let message: String
    }

    // MARK: - Public API

    /// Validates an ordered array of routine steps against layering rules.
    /// Steps whose `stepType` is not in the canonical list (e.g. `.apply`, `.wait`)
    /// are skipped — they can appear anywhere.
    static func validate(steps: [RoutineStep]) -> ValidationResult {
        let indexed = steps.enumerated().compactMap { (offset, step) -> (Int, StepType, Int)? in
            guard let order = layerIndex[step.stepType] else { return nil }
            return (offset, step.stepType, order)
        }

        var violations: [Violation] = []
        var highestSeenOrder = -1
        var highestSeenType: StepType = .cleanse

        for (stepIdx, stepType, order) in indexed {
            if order < highestSeenOrder {
                violations.append(Violation(
                    stepIndex: stepIdx,
                    stepType: stepType,
                    shouldComeBefore: highestSeenType,
                    message: "\(displayName(stepType)) (step \(stepIdx + 1)) should come before \(displayName(highestSeenType))."
                ))
            } else {
                highestSeenOrder = order
                highestSeenType = stepType
            }
        }

        return ValidationResult(isValid: violations.isEmpty, violations: violations)
    }

    /// Suggests the ideal reordering of steps based on layer rules.
    /// Non-canonical step types keep their relative positions interleaved
    /// between the sorted canonical steps.
    static func suggestedOrder(for steps: [RoutineStep]) -> [RoutineStep] {
        // Separate canonical from non-canonical
        var canonical: [(Int, RoutineStep)] = []
        var nonCanonical: [(Int, RoutineStep)] = []

        for (i, step) in steps.enumerated() {
            if layerIndex[step.stepType] != nil {
                canonical.append((i, step))
            } else {
                nonCanonical.append((i, step))
            }
        }

        // Sort canonical steps by layer order
        canonical.sort { (layerIndex[$0.1.stepType] ?? 0) < (layerIndex[$1.1.stepType] ?? 0) }

        // Merge back: place non-canonical steps at their original relative positions
        var result: [RoutineStep] = []
        var cIdx = 0
        var nIdx = 0

        for i in 0..<steps.count {
            if nIdx < nonCanonical.count && nonCanonical[nIdx].0 == i {
                result.append(nonCanonical[nIdx].1)
                nIdx += 1
            } else if cIdx < canonical.count {
                result.append(canonical[cIdx].1)
                cIdx += 1
            }
        }

        // Append any remaining
        while cIdx < canonical.count {
            result.append(canonical[cIdx].1)
            cIdx += 1
        }
        while nIdx < nonCanonical.count {
            result.append(nonCanonical[nIdx].1)
            nIdx += 1
        }

        // Re-number order field
        return result.enumerated().map { (idx, step) in
            RoutineStep(
                id: step.id,
                order: idx,
                productId: step.productId,
                stepType: step.stepType,
                instruction: step.instruction,
                durationSeconds: step.durationSeconds,
                createdAt: step.createdAt,
                updatedAt: Date()
            )
        }
    }

    // MARK: - Display Helpers

    static func displayName(_ type: StepType) -> String {
        switch type {
        case .cleanse:    return "Cleanser"
        case .exfoliate:  return "Exfoliant"
        case .tone:       return "Toner"
        case .treat:      return "Serum / Treatment"
        case .mask:       return "Mask"
        case .moisturize: return "Moisturizer"
        case .protect:    return "Sunscreen"
        case .apply:      return "Apply"
        case .wait:       return "Wait"
        }
    }
}
