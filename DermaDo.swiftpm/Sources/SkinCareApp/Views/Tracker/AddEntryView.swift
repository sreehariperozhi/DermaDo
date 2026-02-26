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
<<<<<<< HEAD
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
=======
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
>>>>>>> mac-ui-major-backup
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
            .colorScheme(.dark)
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
