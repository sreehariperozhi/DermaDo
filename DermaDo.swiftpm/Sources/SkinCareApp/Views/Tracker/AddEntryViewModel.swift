import SwiftUI
import Combine
import PhotosUI

class AddEntryViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let trackerManager: TrackerManagerProtocol
    private let dataManager: DataManagerProtocol
    
    // MARK: - Published State
    @Published var acneCount: Int = 0
    @Published var oilLevel: Double = 5
    @Published var drynessLevel: Double = 5
    @Published var rednessLevel: Double = 5
    @Published var selectedMood: Mood = .neutral
    @Published var notes: String = ""
    @Published var capturedImage: UIImage?
    
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
            mood: selectedMood,
            photoFileName: photoFileName,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes
        )
        
        trackerManager.saveEntry(entry)
    }
}
