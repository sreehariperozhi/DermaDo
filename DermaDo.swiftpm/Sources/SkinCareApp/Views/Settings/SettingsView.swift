import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
        SettingsViewContent(viewModel: SettingsViewModel(
            settingsManager: dependencies.settingsManager,
            backupManager: dependencies.backupManager,
            notificationManager: dependencies.notificationManager
        ))
    }
}

struct SettingsViewContent: View {
    @StateObject var viewModel: SettingsViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            // MARK: - Background
            DesignColors.voidObsidian.ignoresSafeArea()
            
            // Ambient glow
            Circle()
                .fill(DesignColors.ceruleanHydration.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 100)
                .offset(x: -150, y: -250)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignSpacing.heroic) {
                    
                    // MARK: - Header
                    headerSection
                        .editorialReveal(delay: 0.1)

                    // MARK: - Notifications Section
                    notificationSection
                        .editorialReveal(delay: 0.2)

                    // MARK: - Voice Assistant Section
                    voiceSection
                        .editorialReveal(delay: 0.3)

                    // MARK: - Appearance Section
                    appearanceSection
                        .editorialReveal(delay: 0.4)

                    // MARK: - Footer
                    footerSection
                        .editorialReveal(delay: 0.5)
                    
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, DesignSpacing.large)
                .padding(.top, DesignSpacing.editorial)
            }
        }
        .overlay(alignment: .top) {
            // Custom Navbar-ish top bar for modal presentation if needed
            // But we display it as a primary tab usually.
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.micro) {
            Text("PREFERENCES")
                .font(DesignTypography.captionUI)
                .captionTracking()
                .foregroundColor(DesignColors.liquidSilver)
            
            Text("Settings")
                .font(DesignTypography.displayEditorial)
                .foregroundColor(DesignColors.luminousPearl)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            sectionLabel("Notifications")
            
            VStack(spacing: 0) {
                // Master Toggle
                Toggle(isOn: $viewModel.notificationsEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Reminders")
                            .font(DesignTypography.bodyStrongUI)
                            .foregroundColor(DesignColors.luminousPearl)
                        Text("Master control for routine alerts")
                            .font(DesignTypography.captionUI)
                            .foregroundColor(DesignColors.liquidSilver)
                    }
                }
                .tint(DesignColors.roseGold)
                .padding(DesignSpacing.medium)
                
                if viewModel.notificationsEnabled {
                    Divider().background(DesignColors.voidAsh.opacity(0.3))
                        .padding(.horizontal, DesignSpacing.medium)

                    VStack(spacing: DesignSpacing.small) {
                        DatePicker("Morning Routine", selection: $viewModel.morningReminderTime, displayedComponents: .hourAndMinute)
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.luminousPearl)
                        
                        DatePicker("Evening Routine", selection: $viewModel.eveningReminderTime, displayedComponents: .hourAndMinute)
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.luminousPearl)
                    }
                    .padding(DesignSpacing.medium)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .glassCard()
        }
    }

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            sectionLabel("Voice Assistant")
            
            VStack(alignment: .leading, spacing: DesignSpacing.large) {
                // Tone Picker
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    Text("Voice Tone")
                        .font(DesignTypography.captionUI)
                        .foregroundColor(DesignColors.liquidSilver)
                    
                    Picker("Tone", selection: $viewModel.voiceTone) {
                        ForEach(VoiceTone.allCases, id: \.self) { tone in
                            Text(tone.displayName).tag(tone)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Speed Slider
                VStack(alignment: .leading, spacing: DesignSpacing.small) {
                    HStack {
                        Text("Speaking Speed")
                            .font(DesignTypography.captionUI)
                            .foregroundColor(DesignColors.liquidSilver)
                        Spacer()
                        Text(String(format: "%.1fx", viewModel.voiceSpeed))
                            .font(DesignTypography.bodyStrongUI)
                            .foregroundColor(DesignColors.roseGold)
                    }
                    
                    Slider(value: $viewModel.voiceSpeed, in: 0.5...2.0, step: 0.1)
                        .tint(DesignColors.roseGold)
                }
            }
            .padding(DesignSpacing.medium)
            .glassCard()
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.medium) {
            sectionLabel("Appearance")
            
            VStack(spacing: 0) {
                Picker("Theme", selection: $viewModel.selectedTheme) {
                    Text("Light").tag(AppTheme.light)
                    Text("Dark").tag(AppTheme.dark)
                    Text("System").tag(AppTheme.system)
                }
                .pickerStyle(.segmented)
                .padding(DesignSpacing.medium)
            }
            .glassCard()
        }
    }

    private var footerSection: some View {
        VStack(spacing: DesignSpacing.small) {
            Text("Version 2.2.0")
                .font(DesignTypography.microUI)
                .foregroundColor(DesignColors.liquidSilver)
            
            Text("Designed for minimalist skincare rituals.")
                .font(DesignTypography.microUI)
                .italic()
                .foregroundColor(DesignColors.liquidSilver.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSpacing.large)
    }

    // MARK: - UI Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.microUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
            .padding(.leading, 4)
    }
}

// Helper for File Export
struct JSONFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var url: URL?

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        // We don't read from here usually for export
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else { throw CocoaError(.fileNoSuchFile) }
        return try FileWrapper(url: url, options: .immediate)
    }
}
