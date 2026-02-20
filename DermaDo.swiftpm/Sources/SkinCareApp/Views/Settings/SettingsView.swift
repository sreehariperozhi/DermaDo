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
    @State private var isExporting: Bool = false
    @State private var isImporting: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Picker("Theme", selection: $viewModel.selectedTheme) {
                        Label("Light", systemImage: "sun.max")
                            .tag(AppTheme.light)
                        Label("Dark", systemImage: "moon.stars")
                            .tag(AppTheme.dark)
                        Label("System", systemImage: "gear")
                            .tag(AppTheme.system)
                    }
                    .pickerStyle(.inline)
                    .tint(.appAccentPrimary)
                }

                Section(header: Text("Notifications").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                        .tint(.appAccentPrimary)

                    if viewModel.notificationsEnabled {
                        DatePicker("Morning Reminder", selection: $viewModel.morningReminderTime, displayedComponents: .hourAndMinute)
                        DatePicker("Evening Reminder", selection: $viewModel.eveningReminderTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section(header: Text("Data Management").font(.appCaptionText).foregroundColor(.appTextSecondary)) {
                    Button(action: {
                        viewModel.exportData()
                    }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                            .foregroundColor(.appAccentPrimary)
                    }
                    .onChange(of: viewModel.exportURL) { url in
                        if url != nil {
                            isExporting = true
                        }
                    }
                    .fileExporter(
                        isPresented: $isExporting,
                        document: viewModel.exportURL.map { JSONFile(url: $0) },
                        contentType: .json,
                        defaultFilename: "skincare_backup"
                    ) { result in
                        // Handle result
                    }

                    Button(action: {
                        isImporting = true
                    }) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                            .foregroundColor(.appAccentPrimary)
                    }
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: [.json],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                guard url.startAccessingSecurityScopedResource() else { return }
                                viewModel.importData(from: url)
                                url.stopAccessingSecurityScopedResource()
                            }
                        case .failure(let error):
                             print("Import failed: \(error.localizedDescription)")
                        }
                    }
                }

                Section {
                    Text("App Version 1.0.0")
                        .font(.appCaptionText)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $viewModel.showImportSuccess) {
                Alert(title: Text("Success"), message: Text("Data imported successfully."), dismissButton: .default(Text("OK")))
            }
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
