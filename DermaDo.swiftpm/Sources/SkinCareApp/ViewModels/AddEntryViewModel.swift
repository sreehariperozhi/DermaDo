import SwiftUI
import Combine
import PhotosUI

// MARK: - AddEntryViewModel
/// Drives the Add Entry screen: image capture, skin analysis via service, and entry persistence.
/// All business logic lives here — the View only displays state and sends actions.
@MainActor
class AddEntryViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let trackerManager: TrackerManagerProtocol
    private let dataManager: DataManagerProtocol
    private let skinAnalyzerService: SkinAnalyzerServiceProtocol
    
    // MARK: - Published State
    @Published var acneCount: Int = 0
    @Published var oilLevel: Double = 0
    @Published var drynessLevel: Double = 0
    @Published var rednessLevel: Double = 0
    @Published var textureLevel: Double = 0
    @Published var poreLevel: Double = 0
    @Published var selectedMood: Mood = .neutral
    @Published var notes: String = ""
    @Published var capturedImage: UIImage? {
        didSet {
            if let image = capturedImage {
                performAnalysis(image)
            }
        }
    }
    @Published var isAnalyzing: Bool = false
    @Published var showNoFaceAlert: Bool = false
    @Published var showMultipleFacesAlert: Bool = false
    @Published var showLowQualityAlert: Bool = false
    @Published var analysisConfidence: Double = 0.0
    @Published var faceRect: CGRect? = nil
    @Published var showFaceOverlay: Bool = false
    
    /// Stores the last analysis result for inter-scan EMA smoothing
    private var previousAnalysisResult: SkinAnalysisEngine.AnalysisResult?
    
    // MARK: - Init
    init(trackerManager: TrackerManagerProtocol, dataManager: DataManagerProtocol, skinAnalyzerService: SkinAnalyzerServiceProtocol) {
        self.trackerManager = trackerManager
        self.dataManager = dataManager
        self.skinAnalyzerService = skinAnalyzerService
    }
    
    // MARK: - Image Loading
    
    func loadImage(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        self?.capturedImage = image
                    }
                case .failure(let error):
                    print("Error loading image: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Analysis Pipeline
    
    private func performAnalysis(_ image: UIImage) {
        isAnalyzing = true
        
        Task {
            // Step 1: Detect faces via service
            let faces = await skinAnalyzerService.detectFaces(in: image)
            
            await MainActor.run {
                if faces.isEmpty {
                    self.isAnalyzing = false
                    self.capturedImage = nil
                    self.showNoFaceAlert = true
                } else if faces.count > 1 {
                    self.isAnalyzing = false
                    self.capturedImage = nil
                    self.showMultipleFacesAlert = true
                } else if let firstFaceRect = faces.first {
                    // Exactly one face — show overlay then analyze
                    self.faceRect = firstFaceRect
                    
                    withAnimation { self.showFaceOverlay = true }
                    
                    // Brief delay for face highlight overlay visibility
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation { self.showFaceOverlay = false }
                        
                        Task {
                            // Step 2: Analyze via service
                            let result = await self.skinAnalyzerService.analyzeImage(
                                image,
                                previousResult: self.previousAnalysisResult
                            )
                            
                            await MainActor.run {
                                guard let result = result else {
                                    self.isAnalyzing = false
                                    self.showLowQualityAlert = true
                                    return
                                }
                                
                                if result.isLowQuality {
                                    self.isAnalyzing = false
                                    self.capturedImage = nil
                                    self.showLowQualityAlert = true
                                    return
                                }
                                
                                // Smooth slider animation for premium feel
                                withAnimation(.easeOut(duration: 0.4)) {
                                    self.oilLevel = result.oiliness
                                    self.rednessLevel = result.redness
                                    self.textureLevel = result.texture
                                    self.drynessLevel = result.dryness
                                    self.poreLevel = result.pores
                                    self.analysisConfidence = result.confidence
                                    self.isAnalyzing = false
                                }
                                
                                // Store for next scan's EMA smoothing
                                self.previousAnalysisResult = result
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Save Entry
    
    func save() {
        var photoFileName: String? = nil
        
        if let img = capturedImage {
            if let data = img.jpegData(compressionQuality: 0.8) {
                let name = "skin_\(UUID().uuidString).jpg"
                photoFileName = try? dataManager.saveImage(data, withName: name)
            }
        }
        
        let entry = SkinEntry(
            date: Date(),
            acneCount: acneCount,
            oilLevel: Int(oilLevel),
            drynessLevel: Int(drynessLevel),
            rednessLevel: Int(rednessLevel),
            textureLevel: Int(textureLevel),
            poreLevel: Int(poreLevel),
            mood: selectedMood,
            photoFileName: photoFileName,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        
        trackerManager.saveEntry(entry)
    }
}
