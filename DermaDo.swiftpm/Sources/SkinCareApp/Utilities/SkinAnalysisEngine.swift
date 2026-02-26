import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

/// local AI engine for skin analysis using Vision & Core Image.
/// Processes images locally to estimate skin metrics without external API calls.
enum SkinAnalysisEngine {
    
    struct AnalysisResult {
        let oiliness: Double   // 0-10
        let redness: Double    // 0-10
        let texture: Double    // 0-10
        let dryness: Double    // 0-10
    }
    
    static func analyzeImage(_ image: UIImage) async -> AnalysisResult {
        guard let ciImage = CIImage(image: image) else {
            return AnalysisResult(oiliness: 5, redness: 5, texture: 5, dryness: 5)
        }
        
        // 1. Detect ROI (Region of Interest) using Vision (Sendable-safe detectFaces)
        let faces = await detectFaces(in: image)
        let analysisImage: CIImage
        
        if let rawRect = faces.first {
            // Convert normalized Vision coordinates to CIImage coordinates
            let imageSize = ciImage.extent.size
            let origin = ciImage.extent.origin
            
            let denormalizedRect = CGRect(
                x: origin.x + (rawRect.origin.x * imageSize.width),
                y: origin.y + (rawRect.origin.y * imageSize.height),
                width: rawRect.size.width * imageSize.width,
                height: rawRect.size.height * imageSize.height
            )
            analysisImage = ciImage.cropped(to: denormalizedRect)
        } else {
            // Fallback to center crop if no face detected (should be caught by validation layer)
            let width = ciImage.extent.width * 0.4
            let height = ciImage.extent.height * 0.4
            let x = ciImage.extent.origin.x + (ciImage.extent.width - width) / 2
            let y = ciImage.extent.origin.y + (ciImage.extent.height - height) / 2
            analysisImage = ciImage.cropped(to: CGRect(x: x, y: y, width: width, height: height))
        }
        
        // 2. Perform Heuristic Analysis on ROI
        let stats = getAreaAverageColor(analysisImage)
        
        // --- Brightness Calculation (Standard Luma) ---
        // BT.601 formula for luminance
        let brightness = (0.299 * stats.r) + (0.587 * stats.g) + (0.114 * stats.b)
        
        // --- Oiliness Estimation ---
        // Proxied by brightness + specular highlight approximation. 
        // More "shimmer" in skin usually correlates with higher local luminance.
        let oiliness = min(1.0, brightness * 1.3)
        
        // --- Redness Level ---
        // Isolated by comparing Red channel to the average of Blue/Green.
        let avgOther = (stats.g + stats.b) / 2.0
        let rawRedness = max(0, stats.r - avgOther)
        let redness = min(1.0, rawRedness * 10.0) // Boosted for visibility
        
        // --- Texture Roughness ---
        // Scaled to 0-1 range
        let texture = estimateTexture(analysisImage)
        
        // --- Dryness Estimation (Dynamic) ---
        // Inversely related to oiliness, but affected by texture irregularities.
        // If oiliness is low and texture is high, dryness is likely higher.
        let dryness = max(0, min(1.0, (1.0 - oiliness) * 0.8 + (texture * 0.2)))
        
        return AnalysisResult(
            oiliness: clamp(oiliness * 10.0),
            redness: clamp(redness * 10.0),
            texture: clamp(texture * 10.0),
            dryness: clamp(dryness * 10.0)
        )
    }
    
    // MARK: - Public Face Validation
    
    /// Returns detected faces bounding boxes in the image.
    /// Runs on a background thread via async/await.
    static func detectFaces(in image: UIImage) async -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                let faces = (request.results as? [VNFaceObservation])?.map { $0.boundingBox } ?? []
                continuation.resume(returning: faces)
            }
            
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    
    // MARK: - Heuristics
    
    private static func estimateTexture(_ image: CIImage) -> Double {
        let filter = CIFilter.edges()
        filter.inputImage = image
        filter.intensity = 1.0
        
        guard let output = filter.outputImage else { return 0.5 }
        let stats = getAreaAverageColor(output)
        
        // Higher edge density (stats.r) correlates with more texture/irregularity
        return stats.r * 15.0 
    }
    
    private static func getAreaAverageColor(_ image: CIImage) -> (r: Double, g: Double, b: Double) {
        let extent = image.extent
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = extent
        
        guard let outputImage = filter.outputImage else { return (0.5, 0.5, 0.5) }
        
        let context = CIContext(options: [.workingColorSpace : NSNull()])
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return (
            r: Double(bitmap[0]) / 255.0,
            g: Double(bitmap[1]) / 255.0,
            b: Double(bitmap[2]) / 255.0
        )
    }
    
    private static func clamp(_ value: Double) -> Double {
        return max(0, min(10.0, value))
    }
}

// MARK: - Orientation Helper
extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
