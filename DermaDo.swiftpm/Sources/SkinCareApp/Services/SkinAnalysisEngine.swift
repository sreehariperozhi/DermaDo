import SwiftUI
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate

// MARK: - SkinAnalysisEngine

/// A production-grade offline skin analysis engine using Vision + CoreImage + Accelerate.
/// Performs zone-based facial analysis with:
/// - HSV specular-highlight oil detection
/// - R-channel dominance redness/acne mapping
/// - Laplacian + Sobel texture analysis
/// - Dry-patch detection via local variance + desaturation
/// - High-frequency pore detection
/// - Lighting normalization & confidence scoring
/// - EMA inter-scan stability
enum SkinAnalysisEngine {
    
    // MARK: - Result Types
    
    struct AnalysisResult {
        let oiliness: Double      // 0–10
        let redness: Double       // 0–10
        let texture: Double       // 0–10
        let dryness: Double       // 0–10
        let pores: Double         // 0–10
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
        let pores: Double
    }
    
    enum FaceZone: String, CaseIterable {
        case forehead
        case leftCheek
        case rightCheek
        case nose
        case chin
    }
    
    /// Error states for analysis failures
    enum AnalysisError {
        case noFaceDetected
        case multipleFacesDetected
        case lowQualityImage
        case processingFailed
    }
    
    // MARK: - Constants
    
    private static let maxProcessingSize: CGFloat = 640
    private static let sampleDimension: Int = 100
    
    private static let zoneWeights: [FaceZone: Double] = [
        .forehead: 0.20,
        .leftCheek: 0.25,
        .rightCheek: 0.25,
        .nose: 0.15,
        .chin: 0.15
    ]
    
    /// EMA smoothing factor — lower = smoother transitions (0.2 recommended)
    private static let emaAlpha: Double = 0.2
    
    /// Minimum confidence to accept a result
    private static let confidenceThreshold: Double = 0.35
    
    /// Minimum ROI dimension (pixels) to analyze a zone
    private static let minROIDimension: CGFloat = 4.0
    
    // MARK: - Main Entry Point
    
    /// Analyze a face image and return skin metrics.
    /// - Parameters:
    ///   - image: The captured UIImage containing a face.
    ///   - previousResult: Optional previous result for inter-scan EMA smoothing.
    /// - Returns: An `AnalysisResult` with scores scaled 0–10, or `nil` on failure.
    static func analyzeImage(_ image: UIImage, previousResult: AnalysisResult? = nil) async -> AnalysisResult? {
        
        // Step 1: Downscale for performance
        let resized = downsample(image, maxDimension: maxProcessingSize)
        
        guard let ciImage = CIImage(image: resized) else {
            debugLog("❌ Failed to create CIImage from UIImage")
            return nil
        }
        
        // Step 2: Detect face — require exactly one
        let faces = await detectFaces(in: resized)
        guard faces.count == 1, let faceRect = faces.first else {
            debugLog("❌ Face detection failed: found \(faces.count) faces")
            return nil
        }
        
        // Step 3: Compute confidence from image quality
        let imageQuality = assessImageQuality(ciImage)
        let confidence = min(1.0, imageQuality.brightnessScore * 0.4 + imageQuality.sharpnessScore * 0.4 + 0.2)
        
        guard confidence >= confidenceThreshold else {
            debugLog("❌ Image quality too low: confidence=\(String(format: "%.2f", confidence))")
            return AnalysisResult(
                oiliness: 0, redness: 0, texture: 0, dryness: 0, pores: 0,
                confidence: confidence, isLowQuality: true, zoneBreakdown: [:]
            )
        }
        
        // Step 4: Crop to face region with padding
        let faceImage = cropToFace(ciImage, faceRect: faceRect, padding: 0.12)
        
        // Step 5: Normalize lighting
        let normalized = normalizeLighting(faceImage)
        
        // Step 6: Zone segmentation & per-zone analysis
        let zones = segmentZones(normalized)
        var zoneBreakdown: [FaceZone: ZoneMetrics] = [:]
        
        for (zone, zoneImage) in zones {
            // Validate ROI is not empty/tiny
            let extent = zoneImage.extent
            guard extent.width >= minROIDimension, extent.height >= minROIDimension else {
                debugLog("⚠️ Skipping zone \(zone.rawValue): too small (\(extent.width)×\(extent.height))")
                continue
            }
            
            let metrics = analyzeZone(zoneImage, zone: zone, lightingFactor: imageQuality.exposureFactor)
            zoneBreakdown[zone] = metrics
        }
        
        guard !zoneBreakdown.isEmpty else {
            debugLog("❌ No valid zones to analyze")
            return nil
        }
        
        // Step 7: Weighted aggregation across zones
        var totalOil: Double = 0
        var totalRedness: Double = 0
        var totalTexture: Double = 0
        var totalDryness: Double = 0
        var totalPores: Double = 0
        var totalWeight: Double = 0
        
        for (zone, metrics) in zoneBreakdown {
            let weight = zoneWeights[zone] ?? 0.2
            totalOil += metrics.oiliness * weight
            totalRedness += metrics.redness * weight
            totalTexture += metrics.texture * weight
            totalDryness += metrics.dryness * weight
            totalPores += metrics.pores * weight
            totalWeight += weight
        }
        
        // Normalize by actual total weight (in case some zones were skipped)
        if totalWeight > 0 && totalWeight < 1.0 {
            let scale = 1.0 / totalWeight
            totalOil *= scale
            totalRedness *= scale
            totalTexture *= scale
            totalDryness *= scale
            totalPores *= scale
        }
        
        // Step 8: Linear clamping to 0–10 (NO sigmoid compression)
        let rawResult = AnalysisResult(
            oiliness: linearClamp(totalOil),
            redness: linearClamp(totalRedness),
            texture: linearClamp(totalTexture),
            dryness: linearClamp(totalDryness),
            pores: linearClamp(totalPores),
            confidence: confidence,
            isLowQuality: false,
            zoneBreakdown: zoneBreakdown
        )
        
        debugLog("""
        ✅ Analysis complete:
           Oil=\(String(format: "%.1f", rawResult.oiliness)) \
        Red=\(String(format: "%.1f", rawResult.redness)) \
        Tex=\(String(format: "%.1f", rawResult.texture)) \
        Dry=\(String(format: "%.1f", rawResult.dryness)) \
        Pore=\(String(format: "%.1f", rawResult.pores)) \
        Conf=\(String(format: "%.2f", rawResult.confidence))
        """)
        
        // Step 9: Apply EMA smoothing if previous result exists
        guard let prev = previousResult, !prev.isLowQuality else { return rawResult }
        
        return AnalysisResult(
            oiliness: emaSmooth(rawResult.oiliness, previous: prev.oiliness),
            redness: emaSmooth(rawResult.redness, previous: prev.redness),
            texture: emaSmooth(rawResult.texture, previous: prev.texture),
            dryness: emaSmooth(rawResult.dryness, previous: prev.dryness),
            pores: emaSmooth(rawResult.pores, previous: prev.pores),
            confidence: rawResult.confidence,
            isLowQuality: false,
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
                if let error = error {
                    debugLog("⚠️ Face detection error: \(error.localizedDescription)")
                }
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
                debugLog("⚠️ Vision handler failed: \(error.localizedDescription)")
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
            width: min(faceW + padX * 2, extent.width - max(0, faceX - padX - extent.origin.x)),
            height: min(faceH + padY * 2, extent.height - max(0, faceY - padY - extent.origin.y))
        )
        
        return image.cropped(to: cropRect)
    }
    
    /// Normalize lighting using adaptive exposure compensation.
    private static func normalizeLighting(_ image: CIImage) -> CIImage {
        // Step 1: Gentle tone curve to expand midtones
        let toneCurve = CIFilter.toneCurve()
        toneCurve.inputImage = image
        toneCurve.point0 = CGPoint(x: 0.0, y: 0.02)
        toneCurve.point1 = CGPoint(x: 0.18, y: 0.15)
        toneCurve.point2 = CGPoint(x: 0.5, y: 0.50)
        toneCurve.point3 = CGPoint(x: 0.82, y: 0.85)
        toneCurve.point4 = CGPoint(x: 1.0, y: 0.98)
        
        guard let toneOutput = toneCurve.outputImage else { return image }
        
        // Step 2: Measure current brightness for adaptive EV
        let stats = getAreaAverageColor(image)
        let brightness = 0.299 * stats.r + 0.587 * stats.g + 0.114 * stats.b
        
        // Target mid-brightness of ~0.45
        let evAdjust = (0.45 - brightness) * 2.5
        let clampedEV = Float(max(-2.0, min(2.0, evAdjust)))
        
        // Only adjust if significantly off
        guard abs(clampedEV) > 0.15 else { return toneOutput }
        
        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = toneOutput
        exposure.ev = clampedEV
        
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
        
        // Brightness score: bell curve centered at 0.45
        let brightnessScore: Double
        if brightness < 0.12 {
            brightnessScore = brightness / 0.12 * 0.3
        } else if brightness > 0.88 {
            brightnessScore = max(0, 1.0 - (brightness - 0.88) / 0.12 * 0.7)
        } else {
            // Smooth bell: peak at 0.45
            let deviation = abs(brightness - 0.45) / 0.43
            brightnessScore = 0.6 + 0.4 * (1.0 - deviation * deviation)
        }
        
        // Sharpness: edge energy proxy
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = image
        edgeFilter.intensity = 1.0
        
        let sharpnessScore: Double
        if let edgeOutput = edgeFilter.outputImage {
            let edgeStats = getAreaAverageColor(edgeOutput)
            let edgeEnergy = (edgeStats.r + edgeStats.g + edgeStats.b) / 3.0
            sharpnessScore = min(1.0, edgeEnergy * 10.0)
        } else {
            sharpnessScore = 0.5
        }
        
        // Exposure factor: compensate metrics for non-ideal lighting
        let exposureFactor = 1.0 + (0.45 - brightness) * 0.5
        
        return ImageQuality(
            brightnessScore: brightnessScore,
            sharpnessScore: sharpnessScore,
            exposureFactor: max(0.6, min(1.4, exposureFactor))
        )
    }
    
    // MARK: - Zone Segmentation
    
    /// Divide the face into analysis zones based on proportional coordinates.
    /// Uses CIImage coordinate system (origin at bottom-left).
    private static func segmentZones(_ faceImage: CIImage) -> [FaceZone: CIImage] {
        let extent = faceImage.extent
        let x = extent.origin.x
        let y = extent.origin.y
        let w = extent.width
        let h = extent.height
        
        var zones: [FaceZone: CIImage] = [:]
        
        // Forehead: top 28% of face (CIImage: higher Y = higher on screen)
        zones[.forehead] = faceImage.cropped(to: CGRect(
            x: x + w * 0.15, y: y + h * 0.72,
            width: w * 0.70, height: h * 0.26
        ))
        
        // Left Cheek: left 35%, middle band
        zones[.leftCheek] = faceImage.cropped(to: CGRect(
            x: x + w * 0.02, y: y + h * 0.30,
            width: w * 0.32, height: h * 0.35
        ))
        
        // Right Cheek: right 35%, middle band
        zones[.rightCheek] = faceImage.cropped(to: CGRect(
            x: x + w * 0.66, y: y + h * 0.30,
            width: w * 0.32, height: h * 0.35
        ))
        
        // Nose (T-zone): center 30%, middle 30%
        zones[.nose] = faceImage.cropped(to: CGRect(
            x: x + w * 0.35, y: y + h * 0.32,
            width: w * 0.30, height: h * 0.33
        ))
        
        // Chin: bottom 22%
        zones[.chin] = faceImage.cropped(to: CGRect(
            x: x + w * 0.20, y: y + h * 0.02,
            width: w * 0.60, height: h * 0.22
        ))
        
        return zones
    }
    
    // MARK: - Per-Zone Analysis
    
    /// Analyze a single face zone for all five metrics.
    private static func analyzeZone(_ zoneImage: CIImage, zone: FaceZone, lightingFactor: Double) -> ZoneMetrics {
        let oilScore = measureOiliness(zoneImage) * lightingFactor
        let rednessScore = measureRedness(zoneImage)
        let textureScore = measureTexture(zoneImage)
        let drynessScore = measureDryness(zoneImage, textureScore: textureScore, oilScore: oilScore)
        let poreScore = measurePores(zoneImage)
        
        let metrics = ZoneMetrics(
            oiliness: linearClamp(oilScore),
            redness: linearClamp(rednessScore),
            texture: linearClamp(textureScore),
            dryness: linearClamp(drynessScore),
            pores: linearClamp(poreScore)
        )
        
        debugLog("  Zone[\(zone.rawValue)]: oil=\(String(format: "%.1f", metrics.oiliness)) red=\(String(format: "%.1f", metrics.redness)) tex=\(String(format: "%.1f", metrics.texture)) dry=\(String(format: "%.1f", metrics.dryness)) pore=\(String(format: "%.1f", metrics.pores))")
        
        return metrics
    }
    
    // MARK: - Oil Detection (HSV Specular Highlights)
    
    /// Detect oiliness by measuring specular highlights in HSV space.
    /// High Value + Low Saturation pixels indicate shiny/oily skin.
    private static func measureOiliness(_ image: CIImage) -> Double {
        let pixels = samplePixels(from: image)
        guard !pixels.isEmpty else { return 0.0 }
        
        var weightedHighlightSum: Double = 0
        var skinPixelCount: Double = 0
        
        for pixel in pixels {
            let hsv = rgbToHSV(r: pixel.r, g: pixel.g, b: pixel.b)
            let luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b
            
            // Skip non-skin pixels (very dark or near-white)
            guard luminance > 0.10 && luminance < 0.95 else { continue }
            skinPixelCount += 1.0
            
            // Tier 1: Strong specular highlight — very bright + very desaturated
            if hsv.v > 0.80 && hsv.s < 0.18 {
                weightedHighlightSum += 1.0
            }
            // Tier 2: Moderate shine — bright + low saturation
            else if hsv.v > 0.65 && hsv.s < 0.28 {
                weightedHighlightSum += 0.5
            }
            // Tier 3: Mild shine — medium-bright + low-medium saturation
            else if hsv.v > 0.55 && hsv.s < 0.35 {
                weightedHighlightSum += 0.15
            }
        }
        
        guard skinPixelCount > 10 else { return 0.0 }
        
        let ratio = weightedHighlightSum / skinPixelCount
        // Map: 0–0.25 ratio → 0–10 score (linear, no sigmoid)
        return ratio * 40.0
    }
    
    // MARK: - Redness Detection (R-Channel Dominance)
    
    /// Detect redness by analyzing R-channel dominance relative to G/B.
    /// Includes localized inflammation cluster detection for acne-like spots.
    private static func measureRedness(_ image: CIImage) -> Double {
        let pixels = samplePixels(from: image)
        guard !pixels.isEmpty else { return 0.0 }
        
        var totalRednessExcess: Double = 0
        var inflammationCount: Double = 0
        var skinPixelCount: Double = 0
        
        for pixel in pixels {
            let luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b
            
            // Only analyze skin-toned pixels — skip very dark/bright
            guard luminance > 0.12 && luminance < 0.88 else { continue }
            skinPixelCount += 1.0
            
            let avgGB = (pixel.g + pixel.b) / 2.0
            guard avgGB > 0.02 else { continue }
            
            let rRatio = pixel.r / avgGB
            
            // R-channel dominance scoring with graduated thresholds
            if rRatio > 1.10 {
                // Excess redness above baseline
                let excess = rRatio - 1.0
                totalRednessExcess += excess * excess  // Quadratic weighting for stronger redness
            }
            
            // Localized inflammation: strong R-dominance + moderate brightness
            if rRatio > 1.35 && pixel.r > 0.45 && pixel.r < 0.85 {
                inflammationCount += 1.0
            }
        }
        
        guard skinPixelCount > 10 else { return 0.0 }
        
        let avgRedExcess = totalRednessExcess / skinPixelCount
        let clusterRatio = inflammationCount / skinPixelCount
        
        // Combine: baseline redness + localized spots
        let combined = avgRedExcess * 25.0 + clusterRatio * 18.0
        return combined
    }
    
    // MARK: - Texture Analysis (Edge Density + Laplacian Variance)
    
    /// Measure texture roughness using edge density and approximated Laplacian variance.
    private static func measureTexture(_ image: CIImage) -> Double {
        // Method 1: Sobel edge density via CIEdges
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
        
        // Method 2: Laplacian-like variance (original - blurred difference)
        let laplacianVariance = estimateLaplacianVariance(image)
        
        // Combine with separate scaling for each method
        // Edge density captures macro texture; Laplacian captures micro roughness
        let edgeComponent = edgeDensity * 22.0
        let laplacianComponent = laplacianVariance * 28.0
        
        let combined = edgeComponent * 0.45 + laplacianComponent * 0.55
        return combined
    }
    
    /// Estimate Laplacian variance by subtracting blurred from original.
    private static func estimateLaplacianVariance(_ image: CIImage) -> Double {
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = image
        blur.radius = 2.5
        
        guard let blurred = blur.outputImage else { return 0.0 }
        
        let diffFilter = CIFilter.differenceBlendMode()
        diffFilter.inputImage = image
        diffFilter.backgroundImage = blurred
        
        guard let diffOutput = diffFilter.outputImage else { return 0.0 }
        
        let stats = getAreaAverageColor(diffOutput.cropped(to: image.extent))
        return (stats.r + stats.g + stats.b) / 3.0
    }
    
    // MARK: - Dryness Detection
    
    /// Measure dryness through texture roughness, oil inverse, and dry patch detection.
    /// Dry skin characteristics: rough texture, low shine, desaturated patchy areas.
    private static func measureDryness(_ image: CIImage, textureScore: Double, oilScore: Double) -> Double {
        let pixels = samplePixels(from: image)
        guard !pixels.isEmpty else { return 0.0 }
        
        var dryPatchPixels: Double = 0
        var skinPixelCount: Double = 0
        var localVarianceSum: Double = 0
        
        // We need to detect patches that are: moderately bright, very desaturated,
        // but NOT specular highlights (which are oily, not dry).
        for i in 0..<pixels.count {
            let pixel = pixels[i]
            let luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b
            
            guard luminance > 0.10 && luminance < 0.90 else { continue }
            skinPixelCount += 1.0
            
            let hsv = rgbToHSV(r: pixel.r, g: pixel.g, b: pixel.b)
            
            // Dry/flaky patches: tight criteria to avoid over-detection
            // - Moderate brightness (V: 0.40–0.70) — NOT bright highlights (those are oily)
            // - Very low saturation (S < 0.15) — desaturated, ashy appearance
            // - Not too dark (luminance > 0.25)
            if hsv.s < 0.15 && hsv.v > 0.40 && hsv.v < 0.70 && luminance > 0.25 {
                dryPatchPixels += 1.0
            }
            
            // Also detect flakiness via local brightness variance
            // Compare with neighboring pixels (simple approximation)
            if i > 0 {
                let prev = pixels[i - 1]
                let prevLum = 0.299 * prev.r + 0.587 * prev.g + 0.114 * prev.b
                let diff = abs(luminance - prevLum)
                // High local contrast = flaky/rough surface
                if diff > 0.08 {
                    localVarianceSum += diff
                }
            }
        }
        
        guard skinPixelCount > 10 else { return 0.0 }
        
        let patchRatio = dryPatchPixels / skinPixelCount
        let avgLocalVariance = localVarianceSum / skinPixelCount
        
        // Component 1: Dry patches detected
        let patchComponent = patchRatio * 30.0
        
        // Component 2: High texture + low oil = likely dry
        let textureContribution = max(0, textureScore - 2.5) * 0.25
        
        // Component 3: Oil inverse — very low oil strongly suggests dryness
        let oilInverse = max(0, (4.0 - oilScore)) * 0.35
        
        // Component 4: Local variance (flakiness proxy)
        let varianceComponent = avgLocalVariance * 15.0
        
        let combined = patchComponent + textureContribution + oilInverse + varianceComponent
        return combined
    }
    
    // MARK: - Pore Detection (High-Frequency Texture)
    
    /// Detect pores by measuring high-frequency edge density.
    /// Pores appear as small, regular indentations creating fine texture patterns.
    private static func measurePores(_ image: CIImage) -> Double {
        // Step 1: Fine-detail Laplacian (small blur radius for pore-scale features)
        let fineBlur = CIFilter.gaussianBlur()
        fineBlur.inputImage = image
        fineBlur.radius = 1.0
        
        guard let fineBlurred = fineBlur.outputImage else { return 0.0 }
        
        // Fine detail = original - slightly blurred
        let fineDiff = CIFilter.differenceBlendMode()
        fineDiff.inputImage = image
        fineDiff.backgroundImage = fineBlurred
        
        guard let fineDetail = fineDiff.outputImage else { return 0.0 }
        
        let fineStats = getAreaAverageColor(fineDetail.cropped(to: image.extent))
        let fineEnergy = (fineStats.r + fineStats.g + fineStats.b) / 3.0
        
        // Step 2: Edge density at high intensity for fine features
        let edgeFilter = CIFilter.edges()
        edgeFilter.inputImage = image
        edgeFilter.intensity = 2.0
        
        let edgeEnergy: Double
        if let edgeOutput = edgeFilter.outputImage {
            let edgeStats = getAreaAverageColor(edgeOutput)
            edgeEnergy = (edgeStats.r + edgeStats.g + edgeStats.b) / 3.0
        } else {
            edgeEnergy = 0.0
        }
        
        // Step 3: Variance-based scoring — moderate variance = visible pores
        // Very low variance = smooth skin, very high variance = other features
        let combinedEnergy = fineEnergy * 0.6 + edgeEnergy * 0.4
        
        // Map to 0–10 with appropriate scaling
        return combinedEnergy * 45.0
    }
    
    // MARK: - Pixel Sampling
    
    private struct PixelRGB {
        let r: Double
        let g: Double
        let b: Double
    }
    
    /// Sample pixels from a CIImage at reduced resolution for analysis.
    private static func samplePixels(from image: CIImage) -> [PixelRGB] {
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        let extent = image.extent
        
        guard extent.width > 0, extent.height > 0 else { return [] }
        
        let sampleWidth = min(Int(extent.width), sampleDimension)
        let sampleHeight = min(Int(extent.height), sampleDimension)
        
        guard sampleWidth > 0, sampleHeight > 0 else { return [] }
        
        let scaleX = CGFloat(sampleWidth) / extent.width
        let scaleY = CGFloat(sampleHeight) / extent.height
        
        // Transform to origin and scale
        let translated = image.transformed(by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y))
        let scaled = translated.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let pixelCount = sampleWidth * sampleHeight
        var bitmap = [UInt8](repeating: 0, count: pixelCount * 4)
        
        let renderBounds = CGRect(x: 0, y: 0, width: sampleWidth, height: sampleHeight)
        context.render(scaled, toBitmap: &bitmap, rowBytes: sampleWidth * 4,
                      bounds: renderBounds, format: .RGBA8, colorSpace: nil)
        
        var pixels: [PixelRGB] = []
        pixels.reserveCapacity(pixelCount)
        
        for i in 0..<pixelCount {
            pixels.append(PixelRGB(
                r: Double(bitmap[i * 4]) / 255.0,
                g: Double(bitmap[i * 4 + 1]) / 255.0,
                b: Double(bitmap[i * 4 + 2]) / 255.0
            ))
        }
        
        return pixels
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
    
    /// Get area-average RGB values of a CIImage using CIAreaAverage filter.
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
    
    /// Linear clamping to 0–10. No sigmoid, no compression.
    private static func linearClamp(_ value: Double) -> Double {
        return max(0.0, min(10.0, value))
    }
    
    /// Exponential Moving Average for inter-scan stability.
    /// alpha = 0.2 → 20% new value, 80% previous (smooth transitions).
    private static func emaSmooth(_ newValue: Double, previous: Double) -> Double {
        return emaAlpha * newValue + (1.0 - emaAlpha) * previous
    }
    
    /// Debug logging — only active in DEBUG builds.
    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[SkinAnalysis] \(message)")
        #endif
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
