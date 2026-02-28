import Foundation
import Combine
import UIKit

// MARK: - SkinAnalyzerServiceProtocol
/// Contract for skin analysis operations. No SwiftUI dependency.
@MainActor
protocol SkinAnalyzerServiceProtocol: AnyObject {
    /// Analyze a face image and return skin metrics.
    /// - Parameters:
    ///   - image: The captured UIImage containing a face.
    ///   - previousResult: Optional previous result for EMA smoothing.
    /// - Returns: An `AnalysisResult` with 0–10 scores, or `nil` on failure.
    func analyzeImage(_ image: UIImage, previousResult: SkinAnalysisEngine.AnalysisResult?) async -> SkinAnalysisEngine.AnalysisResult?
    
    /// Detect faces in an image and return bounding boxes.
    func detectFaces(in image: UIImage) async -> [CGRect]
}
