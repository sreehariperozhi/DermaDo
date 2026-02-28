import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate

// MARK: - SkinAnalysisEngine

/// A comprehensive offline skin analysis engine using Vision + CoreImage + Accelerate.
/// Performs zone-based facial analysis with HSV oil detection, Laplacian texture analysis,
/// R-channel redness mapping, lighting normalization, confidence scoring, and inter-scan stability.
enum SkinAnalysisEngine {
    
    // MARK: - Result Types
    
    struct AnalysisResult {
        let oiliness: Double      // 0–10
        let redness: Double       // 0–10
        let texture: Double       // 0–10
        let dryness: Double       // 0–10
        let confidence: Double    // 0–1
        let isLowQuality: Bool
        
        /// Per-zone breakdown for diagnostics
        let zoneBreakdown: [FaceZone: ZoneMetrics]
    }
    
    struct ZoneMetrics {
        let oiliness: Double
        let redness: Double
        let texture: Double
        let dryness: Double
    }
    
    enum FaceZone: String, CaseIterable {
        case forehead
        case leftCheek
        case rightCheek
        case nose
        case chin
    }
    
    // MARK: - Constants
    
    private static let maxProcessingSize: CGFloat = 640
    private static let zoneWeights: [FaceZone: Double] = [
        .forehead: 0.20,
        .leftCheek: 0.25,
        .rightCheek: 0.25,
        .nose: 0.15,
        .chin: 0.15
    ]
    
    // Stability smoothing factor (0 = all new, 1 = all old)
    private static let stabilityAlpha: Double = 0.3
    
    // MARK: - Main Entry Point
    
    /// Analyze a face image and return skin metrics.
    /// - Parameters:
    ///   - image: The captured UIImage containing a face.
    ///   - previousResult: Optional previous result for inter-scan stability smoothing.
    /// - Returns: An `AnalysisResult` with scores scaled 0–10.
    static func analyzeImage(_ image: UIImage, previousResult: AnalysisResult? = nil) async -> AnalysisResult {
        
        // Step 1: Downscale for performance
        let resized = downsample(image, maxDimension: maxProcessingSize)
        
        guard let ciImage = CIImage(image: resized) else {
            return fallbackResult()
        }
        
        // Step 2: Detect face
        let faces = await detectFaces(in: resized)
        guard let faceRect = faces.first, faces.count == 1 else {
            return fallbackResult()
        }
        
        // Step 3: Compute confidence from face detection + image quality
        let imageQuality = assessImageQuality(ciImage)
        let confidence = min(1.0, imageQuality.brightnessScore * 0.4 + imageQuality.sharpnessScore * 0.4 + 0.2)
        
        // Step 4: Crop to face region with padding
        let faceImage = cropToFace(ciImage, faceRect: faceRect, padding: 0.1)
        
        // Step 5: Normalize lighting
        let normalized = normalizeLighting(faceImage)
        
        // Step 6: Zone segmentation & per-zone analysis
        let zones = segmentZones(normalized)
        var zoneBreakdown: [FaceZone: ZoneMetrics] = [:]
        
        for (zone, zoneImage) in zones {
            let metrics = analyzeZone(zoneImage, lightingFactor: imageQuality.exposureFactor)
            zoneBreakdown[zone] = metrics
        }
        
        // Step 7: Weighted aggregation across zones
        var totalOil: Double = 0
        var totalRedness: Double = 0
        var totalTexture: Double = 0
        var totalDryness: Double = 0
        
        for (zone, metrics) in zoneBreakdown {
            let weight = zoneWeights[zone] ?? 0.2
            totalOil += metrics.oiliness * weight
            totalRedness += metrics.redness * weight
            totalTexture += metrics.texture * weight
            totalDryness += metrics.dryness * weight
        }
        
        // Step 8: Normalize to 0–10 with sigmoid-like soft clamping
        let rawResult = AnalysisResult(
            oiliness: softClamp(totalOil),
            redness: softClamp(totalRedness),
            texture: softClamp(totalTexture),
            dryness: softClamp(totalDryness),
            confidence: confidence,
            isLowQuality: confidence < 0.4,
            zoneBreakdown: zoneBreakdown
        )
        
        // Step 9: Apply stability smoothing if previous result exists
        guard let prev = previousResult else { return rawResult }
        
        return AnalysisResult(
            oiliness: smoothValue(rawResult.oiliness, previous: prev.oiliness),
            redness: smoothValue(rawResult.redness, previous: prev.redness),
            texture: smoothValue(rawResult.texture, previous: prev.texture),
            dryness: smoothValue(rawResult.dryness, previous: prev.dryness),
            confidence: rawResult.confidence,
            isLowQuality: rawResult.isLowQuality,
            zoneBreakdown: rawResult.zoneBreakdown
        )
    }
    
    // MARK: - Face Detection (Public)
    
    /// Detect face bounding boxes using Vision framework.
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
    
    // MARK: - Image Preprocessing
    
    /// Downscale image to fit within maxDimension while preserving aspect ratio.
    private static func downsample(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        guard scale < 1.0 else { return image }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// Crop CIImage to the detected face bounding box with optional padding.
    private static func cropToFace(_ image: CIImage, faceRect: CGRect, padding: CGFloat) -> CIImage {
        let extent = image.extent
        
        // Vision coordinates are normalized (0–1), bottom-left origin
        let faceX = extent.origin.x + faceRect.origin.x * extent.width
        let faceY = extent.origin.y + faceRect.origin.y * extent.height
        let faceW = faceRect.width * extent.width
        let faceH = faceRect.height * extent.height
        
        // Add padding
        let padX = faceW * padding
        let padY = faceH * padding
        
        let cropRect = CGRect(
            x: max(extent.origin.x, faceX - padX),
            y: max(extent.origin.y, faceY - padY),
            width: min(faceW + padX * 2, extent.width),
            height: min(faceH + padY * 2, extent.height)
        )
        
        return image.cropped(to: cropRect)
    }
    
    /// Normalize lighting using histogram equalization approximation.
    private static func normalizeLighting(_ image: CIImage) -> CIImage {
        // Use tone curve to normalize exposure
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = image
        toneCurve.point0 = CGPoint(x: 0.0, y: 0.0)
        toneCurve.point1 = CGPoint(x: 0.15, y: 0.10)
        toneCurve.point2 = CGPoint(x: 0.5, y: 0.5)
        toneCurve.point3 = CGPoint(x: 0.85, y: 0.90)
        toneCurve.point4 = CGPoint(x: 1.0, y: 1.0)
        
        guard let toneOutput = toneCurve.outputImage else { return image }
        
        // Auto-adjust exposure
        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = toneOutput
        
        // Measure current brightness to decide compensation
        let stats = getAreaAverageColor(image)
        let brightness = 0.299 * stats.r + 0.587 * stats.g + 0.114 * stats.b
        
        // Target mid-brightness of ~0.45
        let evAdjust = (0.45 - brightness) * 2.0
        exposure.ev = Float(max(-1.5, min(1.5, evAdjust)))
        
        return exposure.outputImage ?? toneOutput
    }
    
    // MARK: - Image Quality Assessment
    
    struct ImageQuality {
        let brightnessScore: Double   // 0–1 (1 = ideal brightness)
        let sharpnessScore: Double    // 0–1 (1 = sharp)
        let exposureFactor: Double    // multiplier for metric compensation
    }
    
    private static func assessImageQuality(_ image: CIImage) -> ImageQuality {
        let stats = getAreaAverageColor(image)
        let brightness = 0.299 * stats.r + 0.587 * stats.g + 0.114 * stats.b
        
        // Brightness score: penalize very dark (<0.2) or very bright (>0.8) images
        let brightnessScore: Double
        if brightness < 0.15 {
            brightnessScore = brightness / 0.15 * 0.5
        } else if brightness > 0.85 {
            brightnessScore = max(0, 1.0 - (brightness - 0.85) / 0.15 * 0.5)
        } else {
            brightnessScore = 0.7 + 0.3 * (1.0 - abs(brightness - 0.5) / 0.35)
        }
        
        // Sharpness: use edge energy as proxy
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = image
        edgeFilter.intensity = 1.0
        if let edgeOutput = edgeFilter.outputImage {
            let edgeStats = getAreaAverageColor(edgeOutput)
            let edgeEnergy = (edgeStats.r + edgeStats.g + edgeStats.b) / 3.0
            let sharpness = min(1.0, edgeEnergy * 8.0)
            
            // Exposure factor: compensate metrics for lighting
            let exposureFactor = 1.0 + (0.5 - brightness) * 0.4
            
            return ImageQuality(
                brightnessScore: brightnessScore,
                sharpnessScore: sharpness,
                exposureFactor: max(0.7, min(1.3, exposureFactor))
            )
        }
        
        return ImageQuality(brightnessScore: brightnessScore, sharpnessScore: 0.5, exposureFactor: 1.0)
    }
    
    // MARK: - Zone Segmentation
    
    /// Divide the face into analysis zones based on proportional coordinates.
    private static func segmentZones(_ faceImage: CIImage) -> [FaceZone: CIImage] {
        let extent = faceImage.extent
        let x = extent.origin.x
        let y = extent.origin.y
        let w = extent.width
        let h = extent.height
        
        var zones: [FaceZone: CIImage] = [:]
        
        // Forehead: top 30%
        zones[.forehead] = faceImage.cropped(to: CGRect(
            x: x + w * 0.15, y: y + h * 0.70,
            width: w * 0.70, height: h * 0.28
        ))
        
        // Left Cheek: left 35%, middle 40% height
        zones[.leftCheek] = faceImage.cropped(to: CGRect(
            x: x, y: y + h * 0.30,
            width: w * 0.35, height: h * 0.35
        ))
        
        // Right Cheek: right 35%, middle 40% height
        zones[.rightCheek] = faceImage.cropped(to: CGRect(
            x: x + w * 0.65, y: y + h * 0.30,
            width: w * 0.35, height: h * 0.35
        ))
        
        // Nose: center 30%, middle 30%
        zones[.nose] = faceImage.cropped(to: CGRect(
            x: x + w * 0.35, y: y + h * 0.35,
            width: w * 0.30, height: h * 0.30
        ))
        
        // Chin: bottom 20%
        zones[.chin] = faceImage.cropped(to: CGRect(
            x: x + w * 0.20, y: y,
            width: w * 0.60, height: h * 0.22
        ))
        
        return zones
    }
    
    // MARK: - Per-Zone Analysis
    
    /// Analyze a single face zone for all four metrics.
    private static func analyzeZone(_ zoneImage: CIImage, lightingFactor: Double) -> ZoneMetrics {
        let oilScore = measureOiliness(zoneImage) * lightingFactor
        let rednessScore = measureRedness(zoneImage)
        let textureScore = measureTexture(zoneImage)
        let drynessScore = measureDryness(zoneImage, textureScore: textureScore, oilScore: oilScore)
        
        return ZoneMetrics(
            oiliness: oilScore,
            redness: rednessScore,
            texture: textureScore,
            dryness: drynessScore
        )
    }
    
    // MARK: - Oil Detection (HSV Specular Highlights)
    
    /// Detect oiliness by measuring specular highlights in HSV space.
    /// High Value + Low Saturation pixels indicate shiny/oily skin.
    private static func measureOiliness(_ image: CIImage) -> Double {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let extent = image.extent
        
        guard extent.width > 0, extent.height > 0 else { return 5.0 }
        
        // Sample at reduced resolution for performance
        let sampleWidth = min(Int(extent.width), 80)
        let sampleHeight = min(Int(extent.height), 80)
        
        // Scale the image down for pixel sampling
        let scaleX = CGFloat(sampleWidth) / extent.width
        let scaleY = CGFloat(sampleHeight) / extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let pixelCount = sampleWidth * sampleHeight
        var bitmap = [UInt8](repeating: 0, count: pixelCount * 4)
        
        let renderBounds = CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
        context.render(scaled, toBitmap: &bitmap, rowBytes: sampleWidth * 4,
                      bounds: renderBounds, format: .RGBA8, colorSpace: nil)
        
        var highlightCount: Double = 0
        
        for i in 0..<pixelCount {
            let r = Double(bitmap[i * 4]) / 255.0
            let g = Double(bitmap[i * 4 + 1]) / 255.0
            let b = Double(bitmap[i * 4 + 2]) / 255.0
            
            // Convert to HSV
            let hsv = rgbToHSV(r: r, g: g, b: b)
            
            // Specular highlight: high brightness (V > 0.75) + low saturation (S < 0.25)
            if hsv.v > 0.75 && hsv.s < 0.25 {
                highlightCount += 1.0
            }
            // Moderate shine: medium-high brightness + low-medium saturation
            else if hsv.v > 0.60 && hsv.s < 0.35 {
                highlightCount += 0.4
            }
        }
        
        let ratio = highlightCount / Double(pixelCount)
        // Map: 0–0.20 ratio → 0–10 score
        return min(10.0, ratio * 50.0)
    }
    
    // MARK: - Redness Detection (R-Channel Dominance)
    
    /// Detect redness by analyzing R-channel dominance relative to G/B channels.
    private static func measureRedness(_ image: CIImage) -> Double {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let extent = image.extent
        
        guard extent.width > 0, extent.height > 0 else { return 5.0 }
        
        let sampleWidth = min(Int(extent.width), 80)
        let sampleHeight = min(Int(extent.height), 80)
        
        let scaleX = CGFloat(sampleWidth) / extent.width
        let scaleY = CGFloat(sampleHeight) / extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let pixelCount = sampleWidth * sampleHeight
        var bitmap = [UInt8](repeating: 0, count: pixelCount * 4)
        
        let renderBounds = CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
        context.render(scaled, toBitmap: &bitmap, rowBytes: sampleWidth * 4,
                      bounds: renderBounds, format: .RGBA8, colorSpace: nil)
        
        var totalRednessRatio: Double = 0
        var inflammationClusterCount: Double = 0
        
        for i in 0..<pixelCount {
            let r = Double(bitmap[i * 4]) / 255.0
            let g = Double(bitmap[i * 4 + 1]) / 255.0
            let b = Double(bitmap[i * 4 + 2]) / 255.0
            
            // Skip very dark or very bright pixels (non-skin)
            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            guard luminance > 0.15 && luminance < 0.85 else { continue }
            
            // R-channel dominance ratio
            let avgGB = (g + b) / 2.0
            if avgGB > 0.01 {
                let ratio = r / avgGB
                if ratio > 1.15 {
                    totalRednessRatio += (ratio - 1.0)
                }
                // Localized inflammation: strong redness in a pixel
                if ratio > 1.4 && r > 0.5 {
                    inflammationClusterCount += 1.0
                }
            }
        }
        
        let avgRedness = totalRednessRatio / Double(max(1, pixelCount))
        let clusterRatio = inflammationClusterCount / Double(max(1, pixelCount))
        
        // Combine average redness with inflammation clustering
        let combined = avgRedness * 30.0 + clusterRatio * 20.0
        return min(10.0, combined)
    }
    
    // MARK: - Texture Analysis (Edge Density + Laplacian Variance)
    
    /// Measure texture roughness using edge density and Laplacian-like variance.
    private static func measureTexture(_ image: CIImage) -> Double {
        // Method 1: Sobel edge density
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = image
        edgeFilter.intensity = 1.0
        
        let edgeDensity: Double
        if let edgeOutput = edgeFilter.outputImage {
            let stats = getAreaAverageColor(edgeOutput)
            edgeDensity = (stats.r + stats.g + stats.b) / 3.0
        } else {
            edgeDensity = 0.0
        }
        
        // Method 2: Laplacian-like variance using unsharp mask difference
        let laplacianVariance = estimateLaplacianVariance(image)
        
        // Combine: edge density captures coarse texture, Laplacian captures fine roughness
        let combined = edgeDensity * 0.5 + laplacianVariance * 0.5
        
        // Map to 0–10 scale
        return min(10.0, combined * 35.0)
    }
    
    /// Estimate Laplacian variance by comparing original with blurred version.
    private static func estimateLaplacianVariance(_ image: CIImage) -> Double {
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = image
        blur.radius = 2.0
        
        guard let blurred = blur.outputImage else { return 0.0 }
        
        // Difference between original and blurred approximates Laplacian
        let diffFilter = CIFilter.differenceBlendMode()
        diffFilter.inputImage = image
        diffFilter.backgroundImage = blurred
        
        guard let diffOutput = diffFilter.outputImage else { return 0.0 }
        
        // Get average intensity of the difference (proxy for variance)
        let stats = getAreaAverageColor(diffOutput.cropped(to: image.extent))
        return (stats.r + stats.g + stats.b) / 3.0
    }
    
    // MARK: - Dryness Detection
    
    /// Measure dryness through texture roughness and detection of light dry patches.
    private static func measureDryness(_ image: CIImage, textureScore: Double, oilScore: Double) -> Double {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let extent = image.extent
        
        guard extent.width > 0, extent.height > 0 else { return 5.0 }
        
        let sampleWidth = min(Int(extent.width), 80)
        let sampleHeight = min(Int(extent.height), 80)
        
        let scaleX = CGFloat(sampleWidth) / extent.width
        let scaleY = CGFloat(sampleHeight) / extent.height
        let scaled = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let pixelCount = sampleWidth * sampleHeight
        var bitmap = [UInt8](repeating: 0, count: pixelCount * 4)
        
        let renderBounds = CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
        context.render(scaled, toBitmap: &bitmap, rowBytes: sampleWidth * 4,
                      bounds: renderBounds, format: .RGBA8, colorSpace: nil)
        
        // Detect flaky/dry patches: light, desaturated pixels with surrounding variance
        var dryPatchCount: Double = 0
        
        for i in 0..<pixelCount {
            let r = Double(bitmap[i * 4]) / 255.0
            let g = Double(bitmap[i * 4 + 1]) / 255.0
            let b = Double(bitmap[i * 4 + 2]) / 255.0
            
            let hsv = rgbToHSV(r: r, g: g, b: b)
            
            // Dry/flaky patches: moderately bright, very low saturation, but not specular
            // Distinguishing from oily highlights: dry patches have V in 0.55–0.75 (not ultra-bright)
            if hsv.s < 0.20 && hsv.v > 0.55 && hsv.v < 0.78 {
                dryPatchCount += 1.0
            }
        }
        
        let patchRatio = dryPatchCount / Double(max(1, pixelCount))
        
        // Combine:
        // - High texture + low oil = likely dry
        // - Dry patches detected = additional evidence
        let textureComponent = max(0, textureScore - 3.0) * 0.3
        let oilInverse = max(0, (5.0 - oilScore)) * 0.3
        let patchComponent = patchRatio * 40.0
        
        let combined = textureComponent + oilInverse + patchComponent
        return min(10.0, combined)
    }
    
    // MARK: - Helpers
    
    /// Convert RGB to HSV color space.
    private static func rgbToHSV(r: Double, g: Double, b: Double) -> (h: Double, s: Double, v: Double) {
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC
        
        let v = maxC
        let s = maxC > 0 ? delta / maxC : 0
        
        var h: Double = 0
        if delta > 0 {
            if maxC == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            h /= 6.0
            if h < 0 { h += 1.0 }
        }
        
        return (h, s, v)
    }
    
    /// Get area-average RGB values of a CIImage.
    private static func getAreaAverageColor(_ image: CIImage) -> (r: Double, g: Double, b: Double) {
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return (0.5, 0.5, 0.5) }
        
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = extent
        
        guard let outputImage = filter.outputImage else { return (0.5, 0.5, 0.5) }
        
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4,
                      bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                      format: .RGBA8, colorSpace: nil)
        
        return (
            r: Double(bitmap[0]) / 255.0,
            g: Double(bitmap[1]) / 255.0,
            b: Double(bitmap[2]) / 255.0
        )
    }
    
    /// Soft sigmoid-like clamping to 0–10, avoiding hard boundaries.
    private static func softClamp(_ value: Double) -> Double {
        // Use tanh-based soft clamp: maps (-∞, +∞) → (0, 10)
        // But we're already roughly in range, so just smooth the edges
        let normalized = max(0, min(10, value))
        // Slight compression at extremes to avoid stuck-at-0 / stuck-at-10
        return 0.5 + 9.0 * (1.0 / (1.0 + exp(-0.5 * (normalized - 5.0))))
    }
    
    /// Exponential moving average for inter-scan stability.
    private static func smoothValue(_ newValue: Double, previous: Double) -> Double {
        return (1.0 - stabilityAlpha) * newValue + stabilityAlpha * previous
    }
    
    /// Fallback result when analysis cannot be performed.
    private static func fallbackResult() -> AnalysisResult {
        return AnalysisResult(
            oiliness: 5, redness: 5, texture: 5, dryness: 5,
            confidence: 0.0, isLowQuality: true,
            zoneBreakdown: [:]
        )
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
