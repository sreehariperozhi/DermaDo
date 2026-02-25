import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// local AI engine for skin analysis using Vision & Core Image.
/// Processes images locally to estimate skin metrics without external API calls.
enum SkinAnalysisEngine {
    
    struct AnalysisResult {
        let brightness: Double // 0.0 - 1.0 (Oiliness estimate)
        let redness: Double    // 0.0 - 1.0 (Redness estimate)
        let texture: Double    // 0.0 - 1.0 (Roughness/Detail estimate)
    }
    
    /// Analyzes a skin photo and returns estimated metrics.
    /// - Parameter image: The UIImage to analyze.
    /// - Returns: AnalysisResult with normalized values.
    static func analyzeImage(_ image: UIImage) async -> AnalysisResult {
        guard let ciImage = CIImage(image: image) else {
            return AnalysisResult(brightness: 0.5, redness: 0.5, texture: 0.5)
        }
        
        // 1. Estimate Brightness/Oiliness (Specularity)
        let brightness = estimateBrightness(ciImage)
        
        // 2. Estimate Redness
        let redness = estimateRedness(ciImage)
        
        // 3. Estimate Texture (Detail density)
        let texture = estimateTexture(ciImage)
        
        return AnalysisResult(
            brightness: clamp(brightness),
            redness: clamp(redness),
            texture: clamp(texture)
        )
    }
    
    // MARK: - Private Heuristics
    
    /// Estimates brightness roughly mapping to skin oiliness (specular highlights).
    private static func estimateBrightness(_ image: CIImage) -> Double {
        let stats = getAreaAverageColor(image)
        // Luma formula: 0.299R + 0.587G + 0.114B
        let luma = 0.299 * stats.r + 0.587 * stats.g + 0.114 * stats.b
        return luma
    }
    
    /// Estimates redness by looking for red channel dominance.
    private static func estimateRedness(_ image: CIImage) -> Double {
        let stats = getAreaAverageColor(image)
        // Simple heuristic: Red dominance over Green/Blue
        let totalVal = stats.r + stats.g + stats.b
        guard totalVal > 0 else { return 0 }
        
        let redRatio = stats.r / (totalVal / 3.0)
        // redRatio > 1.2 is usually quite red
        return (redRatio - 1.0) * 2.0
    }
    
    /// Estimates texture by checking edge/detail density.
    private static func estimateTexture(_ image: CIImage) -> Double {
        let context = CIContext()
        let filter = CIFilter.edges()
        filter.inputImage = image
        filter.intensity = 1.0
        
        guard let output = filter.outputImage else { return 0.5 }
        let stats = getAreaAverageColor(output)
        
        // Edge density is higher for rougher texture/acne
        return stats.r * 10.0 // Scaled for visibility
    }
    
    // MARK: - Core Image Helpers
    
    private static func getAreaAverageColor(_ image: CIImage) -> (r: Double, g: Double, b: Double) {
        let extent = image.extent
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = extent
        
        guard let outputImage = filter.outputImage else { return (0.5, 0.5, 0.5) }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return (
            r: Double(bitmap[0]) / 255.0,
            g: Double(bitmap[1]) / 255.0,
            b: Double(bitmap[2]) / 255.0
        )
    }
    
    private static func clamp(_ value: Double) -> Double {
        return max(0, min(1, value))
    }
}
