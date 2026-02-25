import SwiftUI

struct AddEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var viewModel: AddEntryViewModel

    @State private var showingCamera = false
    @State private var showingSourceDialog = false
    @State private var selectedSourceType: UIImagePickerController.SourceType = .camera

    var onSaved: (() -> Void)?

    var body: some View {
        NavigationView {
            Form {
                // Photo Section
                Section(header: Text("Photo").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    ZStack {
                        if let image = viewModel.capturedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .overlay(
                                    Group {
                                        if viewModel.isAnalyzing {
                                            ZStack {
                                                Color.black.opacity(0.4)
                                                VStack(spacing: 8) {
                                                    ProgressView()
                                                        .tint(.white)
                                                    Text("Analyzing Skin...")
                                                        .font(.appCaptionText)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                        }
                                    }
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.appBackgroundSecondary)
                                .frame(height: 200)

                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 28))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appTextTertiary)
                                Text("Tap to add photo")
                                    .font(.appBody)
                                    .foregroundColor(.appTextTertiary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        showingSourceDialog = true
                    }
                }

                // Trackers
                Section(header: Text("Levels (0-10)").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Oil: \(Int(viewModel.oilLevel))")
                            if viewModel.isAnalyzing { Image(systemName: "sparkles").foregroundColor(.appAccentPrimary).font(.system(size: 10)) }
                        }
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                        Slider(value: $viewModel.oilLevel, in: 0...10, step: 1)
                            .tint(.appWarning)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Dryness: \(Int(viewModel.drynessLevel))")
                        }
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                        Slider(value: $viewModel.drynessLevel, in: 0...10, step: 1)
                            .tint(.appAccentPrimary)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Redness: \(Int(viewModel.rednessLevel))")
                            if viewModel.isAnalyzing { Image(systemName: "sparkles").foregroundColor(.appAccentPrimary).font(.system(size: 10)) }
                        }
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                        Slider(value: $viewModel.rednessLevel, in: 0...10, step: 1)
                            .tint(.appError)
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Texture: \(Int(viewModel.textureLevel))")
                            if viewModel.isAnalyzing { Image(systemName: "sparkles").foregroundColor(.appAccentPrimary).font(.system(size: 10)) }
                        }
                        .font(.appBody)
                        .foregroundColor(.appTextPrimary)
                        Slider(value: $viewModel.textureLevel, in: 0...10, step: 1)
                            .tint(.appAccentSecondary)
                    }
                }

                Section(header: Text("Acne Count").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Stepper("Count: \(viewModel.acneCount)", value: $viewModel.acneCount, in: 0...50)
                        .font(.appBody)
                }

                // Mood — SF Symbols instead of emojis
                Section(header: Text("Mood").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedMood = mood
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: mood.sfSymbol)
                                            .font(.system(size: 24))
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundColor(viewModel.selectedMood == mood ? .appAccentPrimary : .appTextTertiary)

                                        Text(mood.displayName)
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(viewModel.selectedMood == mood ? .appAccentPrimary : .appTextTertiary)
                                    }
                                    .padding(AppSpacing.xs)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppSpacing.radiusSmall, style: .continuous)
                                            .fill(viewModel.selectedMood == mood ? Color.appAccentSubtle : Color.clear)
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section(header: Text("Notes").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    TextEditor(text: $viewModel.notes)
                        .frame(height: 100)
                        .font(.appBody)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.appAccentPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.save()
                        onSaved?()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.appAccentPrimary)
                }
            }
            .confirmationDialog("Choose Photo Source", isPresented: $showingSourceDialog, titleVisibility: .visible) {
                Button("Camera") {
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
        }
    }
}

// MARK: - Mood Extensions

extension Mood {
    /// SF Symbol name for each mood (replaces emoji).
    var sfSymbol: String {
        switch self {
        case .great:    return "face.smiling"
        case .good:     return "hand.thumbsup"
        case .neutral:  return "minus.circle"
        case .stressed: return "cloud.bolt"
        case .tired:    return "moon.zzz"
        case .anxious:  return "exclamationmark.triangle"
        case .sad:      return "drop"
        }
    }

    /// Display name for the mood.
    var displayName: String {
        switch self {
        case .great:    return "Great"
        case .good:     return "Good"
        case .neutral:  return "Neutral"
        case .stressed: return "Stressed"
        case .tired:    return "Tired"
        case .anxious:  return "Anxious"
        case .sad:      return "Sad"
        }
    }

    /// Legacy emoji property (kept for backward compat).
    var emoji: String {
        switch self {
        case .great:    return "face.smiling"
        case .good:     return "hand.thumbsup"
        case .neutral:  return "minus.circle"
        case .stressed: return "cloud.bolt"
        case .tired:    return "moon.zzz"
        case .anxious:  return "exclamationmark.triangle"
        case .sad:      return "drop"
        }
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
