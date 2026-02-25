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

    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Notifications
                Section {
                    Toggle(isOn: $viewModel.notificationsEnabled) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.appAccentPrimary)
                                .symbolRenderingMode(.hierarchical)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications")
                                    .font(.appBody)
                                Text("Master control for all reminders")
                                    .font(.appCaptionText)
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                    }
                    .tint(.appAccentPrimary)

                    if viewModel.notificationsEnabled {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text("Default Reminder Times")
                                .font(.appCaptionText)
                                .foregroundColor(.appTextSecondary)
                                .padding(.top, 4)
                            
                            DatePicker("Morning Routine", selection: $viewModel.morningReminderTime, displayedComponents: .hourAndMinute)
                                .font(.appBody)
                            
                            DatePicker("Evening Routine", selection: $viewModel.eveningReminderTime, displayedComponents: .hourAndMinute)
                                .font(.appBody)
                        }
                        .padding(.vertical, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                } header: {
                    Text("Notifications").font(.appCaptionText).foregroundColor(.appTextSecondary)
                }

                // Section 2: Voice
                Section {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "waveform")
                                .foregroundColor(.appAccentPrimary)
                            Text("Voice Tone")
                                .font(.appBody)
                            Spacer()
                            Picker("Tone", selection: $viewModel.voiceTone) {
                                ForEach(VoiceTone.allCases, id: \.self) { tone in
                                    Text(tone.displayName).tag(tone)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.appAccentPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Speaking Speed")
                                    .font(.appBody)
                                Spacer()
                                Text(String(format: "%.1fx", viewModel.voiceSpeed))
                                    .font(.appNumericSmall)
                                    .foregroundColor(.appAccentPrimary)
                            }
                            
                            Slider(value: $viewModel.voiceSpeed, in: 0.5...2.0, step: 0.1)
                                .tint(.appAccentPrimary)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Voice Assistant").font(.appCaptionText).foregroundColor(.appTextSecondary)
                }

                // Section 3: Appearance
                Section {
                    Picker("Theme", selection: $viewModel.selectedTheme) {
                        Label("Light", systemImage: "sun.max")
                            .tag(AppTheme.light)
                        Label("Dark", systemImage: "moon.stars")
                            .tag(AppTheme.dark)
                        Label("System", systemImage: "gearshape")
                            .tag(AppTheme.system)
                    }
                    .pickerStyle(.inline)
                    .tint(.appAccentPrimary)
                } header: {
                    Text("Appearance").font(.appCaptionText).foregroundColor(.appTextSecondary)
                }

                // Footer
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Version 2.1.0")
                            .font(.appCaptionText)
                            .foregroundColor(.appTextTertiary)
                        Text("Designed with care for your skin.")
                            .font(.system(size: 10, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.appTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
            .animation(.default, value: viewModel.notificationsEnabled)
        }
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
