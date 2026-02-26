import SwiftUI
import Combine
import PhotosUI

@MainActor
class AddEntryViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let trackerManager: TrackerManagerProtocol
    private let dataManager: DataManagerProtocol
    
    // MARK: - Published State
    @Published var acneCount: Int = 0
    @Published var oilLevel: Double = 5
    @Published var drynessLevel: Double = 5
    @Published var rednessLevel: Double = 5
    @Published var textureLevel: Double = 5
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
    @Published var faceRect: CGRect? = nil
    @Published var showFaceOverlay: Bool = false
    
    // MARK: - Init
    init(trackerManager: TrackerManagerProtocol, dataManager: DataManagerProtocol) {
        self.trackerManager = trackerManager
        self.dataManager = dataManager
    }
    
    // MARK: - Actions
    
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
    
    private func performAnalysis(_ image: UIImage) {
        isAnalyzing = true
        
        Task {
            // Step 1: Detect all faces (background thread via async)
            let faces = await SkinAnalysisEngine.detectFaces(in: image)
            
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
                    // Exactly one face - proceed
                    self.faceRect = firstFaceRect
                    
                    // Briefly show highlight overlay
                    withAnimation { self.showFaceOverlay = true }
                    
                    // Delay analysis slightly to allow the user to see the highlight
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { self.showFaceOverlay = false }
                        
                        // Proceed to Step 2: Skin Analysis
                        Task {
                            let result = await SkinAnalysisEngine.analyzeImage(image)
                            
                            await MainActor.run {
                                withAnimation(.spring()) {
                                    self.oilLevel = result.oiliness
                                    self.rednessLevel = result.redness
                                    self.textureLevel = result.texture
                                    self.drynessLevel = result.dryness
                                    self.isAnalyzing = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    func save() {
        var photoFileName: String? = nil
        
        if let img = capturedImage {
            // Save image logic
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
            mood: selectedMood,
            photoFileName: photoFileName,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        
        trackerManager.saveEntry(entry)
    }
}
