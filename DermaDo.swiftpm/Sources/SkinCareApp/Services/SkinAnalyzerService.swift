import Foundation
import UIKit

// MARK: - SkinAnalyzerService
/// Service layer wrapping SkinAnalysisEngine. No SwiftUI dependency.
/// Provides async image analysis and face detection for ViewModels.
@MainActor
final class SkinAnalyzerService: SkinAnalyzerServiceProtocol {
    
    // MARK: - Analysis
    
    func analyzeImage(_ image: UIImage, previousResult: SkinAnalysisEngine.AnalysisResult? = nil) async -> SkinAnalysisEngine.AnalysisResult? {
        return await SkinAnalysisEngine.analyzeImage(image, previousResult: previousResult)
    }
    
    // MARK: - Face Detection
    
    func detectFaces(in image: UIImage) async -> [CGRect] {
        return await SkinAnalysisEngine.detectFaces(in: image)
    }
}
