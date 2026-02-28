
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
        SettingsViewContent(viewModel: SettingsViewModel(
            settingsManager: dependencies.settingsManager,
            backupManager: dependencies.backupManager,
            notificationManager: dependencies.notificationManager,
            userManager: dependencies.userManager
        ))
    }
}

struct SettingsViewContent: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var userSession: UserSessionViewModel
    @AppStorage("hasCompletedProfileSetup") private var hasCompletedProfileSetup: Bool = false
    
    // Banner condition: if name is empty or no skin goals are selected, and they haven't permanently hidden it.
    private var showProfileBanner: Bool {
        if hasCompletedProfileSetup { return false }
        let isComplete = !userSession.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !userSession.skinGoals.isEmpty
        if isComplete {
            // Auto complete if they meet conditions
            DispatchQueue.main.async {
                hasCompletedProfileSetup = true
            }
            return false
        }
        return true
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Background Layer
                backgroundLayer
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: DesignSpacing.heroic) {
                        
                        // MARK: - Header
                        headerSection
                            .editorialReveal(delay: 0.1)
                        
                        // MARK: - Banner
                        if showProfileBanner {
                            profileSetupBanner
                                .editorialReveal(delay: 0.15)
                        }
                        
                        // MARK: - Core Navigation
                        coreNavigationSection
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
                        
                    }
                    .padding(.horizontal, DesignSpacing.large)
                    .padding(.top, DesignSpacing.standard)
                }
            }
            // Hide the default iOS Navigation Bar since we provide a custom header
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            DesignColors.voidObsidian.ignoresSafeArea()

            // Ambient cerulean orb
            Circle()
                .fill(DesignColors.ceruleanHydration.opacity(0.1))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -150, y: -250)
        }
    }
    
    // MARK: - Header Section
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

    // MARK: - Banner
    private var profileSetupBanner: some View {
        NavigationLink(destination: ProfileDetailView()) {
            HStack(spacing: DesignSpacing.medium) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.title)
                    .foregroundColor(DesignColors.roseGold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Setup Your Profile")
                        .font(DesignTypography.bodyStrongUI)
                        .foregroundColor(DesignColors.luminousPearl)
                    
                    Text("Complete your profile for personalized routines.")
                        .font(DesignTypography.captionUI)
                        .foregroundColor(DesignColors.liquidSilver)
                }
                
                Spacer()
                
                Text("Complete")
                    .font(DesignTypography.captionUI.weight(.bold))
                    .foregroundColor(DesignColors.voidObsidian)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DesignColors.roseGold)
                    .clipShape(Capsule())
            }
            .padding(DesignSpacing.standard)
            .background(DesignColors.voidAsh.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DesignRadius.container))
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.container)
                    .stroke(DesignColors.roseGold.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sections
    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(DesignTypography.microUI)
            .captionTracking()
            .foregroundColor(DesignColors.liquidSilver)
            .padding(.leading, 4)
    }

    private var coreNavigationSection: some View {
        VStack(spacing: 0) {
            settingsNavRow(title: "Profile", icon: "person.crop.circle", isTop: true, isBottom: false) {
                ProfileDetailView()
            }
            
            Divider().background(DesignColors.voidAsh.opacity(0.3)).padding(.horizontal, DesignSpacing.medium)
            
            settingsNavRow(title: "Notifications", icon: "bell.badge", isTop: false, isBottom: false) {
                NotificationsView(viewModel: viewModel)
            }
            
            Divider().background(DesignColors.voidAsh.opacity(0.3)).padding(.horizontal, DesignSpacing.medium)
            
            settingsNavRow(title: "Privacy", icon: "hand.raised.fill", isTop: false, isBottom: true) {
                PrivacyView()
            }
        }
        .glassCard()
    }
    
    private func settingsNavRow<Destination: View>(title: String, icon: String, isTop: Bool, isBottom: Bool, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DesignColors.roseGold)
                    .font(.title3)
                    .frame(width: 30)
                
                Text(title)
                    .font(DesignTypography.bodyUI)
                    .foregroundColor(DesignColors.luminousPearl)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(DesignSpacing.medium)
            .contentShape(Rectangle()) // makes entire row tappable
        }
        .buttonStyle(.plain)
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

