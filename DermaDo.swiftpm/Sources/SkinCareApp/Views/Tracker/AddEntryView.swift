import SwiftUI

struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AddEntryViewModel

    @State private var showingCamera = false
    @State private var showingSourceDialog = false
    @State private var selectedSourceType: UIImagePickerController.SourceType = .camera
    @State private var appeared = false

    var onSaved: (() -> Void)?

    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Background
                DesignColors.voidObsidian.ignoresSafeArea()
                
                // Ambient orb
                Circle()
                    .fill(DesignColors.roseGold.opacity(0.05))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 100, y: -200)

                Form {
                    // MARK: - Photo Section
                    Section(header: sectionHeader("Visual Log")) {
                        ZStack {
                            if let image = viewModel.capturedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 240)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous)
                                            .stroke(DesignShadows.innerGlow, lineWidth: 1)
                                    )
                                    .overlay(
                                        Group {
                                            if viewModel.isAnalyzing {
                                                ZStack {
                                                    Color.black.opacity(0.4)
                                                    VStack(spacing: 8) {
                                                        ProgressView()
                                                            .tint(.white)
                                                        Text("Analyzing Skin...")
                                                            .font(DesignTypography.captionUI)
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous))
                                            }
                                            
                                            if viewModel.showFaceOverlay, let rect = viewModel.faceRect {
                                                GeometryReader { geo in
                                                    let width = rect.width * geo.size.width
                                                    let height = rect.height * geo.size.height
                                                    let x = rect.origin.x * geo.size.width
                                                    let y = (1.0 - rect.origin.y - rect.height) * geo.size.height
                                                    
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .stroke(DesignColors.roseGold, lineWidth: 2)
                                                        .background(DesignColors.roseGold.opacity(0.1))
                                                        .frame(width: width, height: height)
                                                        .offset(x: x, y: y)
                                                        .transition(.opacity.combined(with: .scale))
                                                }
                                            }
                                        }
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous)
                                    .fill(DesignColors.voidAsh.opacity(0.5))
                                    .frame(height: 240)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignRadius.container, style: .continuous)
                                            .stroke(DesignShadows.innerGlow, lineWidth: 1)
                                    )

                                VStack(spacing: DesignSpacing.small) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(DesignColors.liquidSilver)
                                    Text("Capture Skin Progress")
                                        .font(DesignTypography.bodyUI)
                                        .foregroundColor(DesignColors.liquidSilver)
                                }
                            }
                        }
                        .onTapGesture {
                            showingSourceDialog = true
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: DesignSpacing.medium, trailing: 0))

                    // MARK: - Levels Section
                    Section(header: sectionHeader("Skin Levels (0-10)")) {
                        VStack(spacing: DesignSpacing.medium) {
                            levelSlider(title: "Oil Level", value: $viewModel.oilLevel, color: DesignColors.ceruleanHydration)
                            levelSlider(title: "Dryness Level", value: $viewModel.drynessLevel, color: DesignColors.roseGold)
                            levelSlider(title: "Redness Level", value: $viewModel.rednessLevel, color: DesignColors.velvetCrimson)
                            levelSlider(title: "Texture Level", value: $viewModel.textureLevel, color: DesignColors.sageBotanical)
                        }
                        .padding(.vertical, DesignSpacing.small)
                    }
                    .listRowBackground(DesignColors.voidAsh.opacity(0.5))

                    // MARK: - Acne Count
                    Section(header: sectionHeader("Blemishes")) {
                        Stepper(value: $viewModel.acneCount, in: 0...50) {
                            HStack {
                                Text("Acne Count")
                                    .font(DesignTypography.bodyUI)
                                    .foregroundColor(DesignColors.luminousPearl)
                                Spacer()
                                Text("\(viewModel.acneCount)")
                                    .font(DesignTypography.titleUI)
                                    .foregroundColor(DesignColors.sageBotanical)
                            }
                        }
                    }
                    .listRowBackground(DesignColors.voidAsh.opacity(0.5))

                    // MARK: - Mood Section
                    Section(header: sectionHeader("Mood")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignSpacing.small) {
                                ForEach(Mood.allCases, id: \.self) { mood in
                                    MoodButton(mood: mood, isSelected: viewModel.selectedMood == mood) {
                                        withAnimation(DesignMotion.tactilePress) {
                                            viewModel.selectedMood = mood
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))

                    // MARK: - Notes Section
                    Section(header: sectionHeader("Observations")) {
                        TextEditor(text: $viewModel.notes)
                            .frame(height: 120)
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.luminousPearl)
                            .scrollContentBackground(.hidden)
                            .background(DesignColors.voidAsh.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 100, trailing: 0))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(DesignColors.liquidSilver)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.save()
                        onSaved?()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(DesignColors.roseGold)
                }
            }
            .confirmationDialog("Analyze Progress", isPresented: $showingSourceDialog, titleVisibility: .visible) {
                Button("Launch Camera") {
                    selectedSourceType = .camera
                    showingCamera = true
                }
                Button("Photo Library") {
                    selectedSourceType = .photoLibrary
                    showingCamera = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePickerCompat(image: $viewModel.capturedImage, sourceType: selectedSourceType)
            }
            .alert("No Face Detected", isPresented: $viewModel.showNoFaceAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No face detected. Please capture a clear face image.")
            }
            .alert("Multiple Faces Detected", isPresented: $viewModel.showMultipleFacesAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Multiple faces detected. Please capture only your face for accurate analysis.")
            }
            .alert("Image Quality Too Low", isPresented: $viewModel.showLowQualityAlert) {
                Button("Retake", role: .cancel) { }
            } message: {
                Text("The image quality is too low for accurate analysis. Please retake with better lighting and hold your device steady.")
            }
        }
    }

    // MARK: - Components
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.microUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
            .padding(.leading, 4)
    }

    private func levelSlider(title: String, value: Binding<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.liquidSilver)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(color)
            }
            Slider(value: value, in: 0...10, step: 1)
                .tint(color)
        }
    }
}

// MARK: - Supporting Views
struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mood.sfSymbol)
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isSelected ? DesignColors.roseGold : DesignColors.liquidSilver)
                
                Text(mood.displayName)
                    .font(DesignTypography.microUI)
                    .foregroundColor(isSelected ? DesignColors.roseGold : DesignColors.liquidSilver)
            }
            .frame(width: 70, height: 75)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? DesignColors.roseGold.opacity(0.1) : DesignColors.voidAsh.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? DesignColors.roseGold.opacity(0.3) : DesignColors.voidAsh.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ImagePickerCompat

struct ImagePickerCompat: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerCompat
        init(_ parent: ImagePickerCompat) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            picker.dismiss(animated: true)
        }
    }
}
