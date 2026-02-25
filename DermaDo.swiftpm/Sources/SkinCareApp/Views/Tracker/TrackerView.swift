import SwiftUI
import UIKit
import Charts

struct TrackerView: View {
    @EnvironmentObject var dependencies: AppDependencies
    var body: some View {
        TrackerViewContent(viewModel: TrackerViewModel(trackerManager: dependencies.trackerManager, dataManager: dependencies.dataManager))
    }
}

struct TrackerViewContent: View {
    @EnvironmentObject var dependencies: AppDependencies
    @StateObject var viewModel: TrackerViewModel
    @State private var showingAddEntry = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {

                    // Period Selector
                    Picker("Period", selection: $viewModel.selectedPeriod) {
                        Text("Week").tag(TrackerViewModel.Period.week)
                        Text("Month").tag(TrackerViewModel.Period.month)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                    // Chart
                    CardView {
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 16))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appAccentPrimary)

                                Text("Skin Trends")
                                    .font(.appSectionTitle)
                                    .foregroundColor(.appTextPrimary)
                            }

                            if !viewModel.periodEntries.isEmpty {
                                Chart {
                                    ForEach(viewModel.periodEntries) { entry in
                                        LineMark(
                                            x: .value("Date", entry.date),
                                            y: .value("Oil", entry.oilLevel)
                                        )
                                        .foregroundStyle(Color.appWarning)
                                        .symbol(Circle())
                                        .interpolationMethod(.catmullRom)

                                        LineMark(
                                            x: .value("Date", entry.date),
                                            y: .value("Dryness", entry.drynessLevel)
                                        )
                                        .foregroundStyle(Color.appAccentPrimary)
                                        .symbol(Circle())
                                        .interpolationMethod(.catmullRom)

                                        LineMark(
                                            x: .value("Date", entry.date),
                                            y: .value("Redness", entry.rednessLevel)
                                        )
                                        .foregroundStyle(Color.appError)
                                        .symbol(Circle())
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .frame(height: 200)
                                .chartYScale(domain: 0...10)
                                .chartXAxis {
                                    AxisMarks(values: .automatic) { value in
                                        if viewModel.selectedPeriod == .week {
                                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                                        } else {
                                            AxisValueLabel(format: .dateTime.day())
                                        }
                                        AxisGridLine()
                                    }
                                }
                                .animation(.easeInOut(duration: 0.25), value: viewModel.selectedPeriod)
                            } else {
                                Text("No data for this period")
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.appTextTertiary)
                                    .font(.appBody)
                            }

                            // Legend
                            HStack(spacing: AppSpacing.md) {
                                LegendItem(name: "Oil", color: .appWarning)
                                LegendItem(name: "Dryness", color: .appAccentPrimary)
                                LegendItem(name: "Redness", color: .appError)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                    // Stats — using SF Symbols instead of emojis
                    HStack(spacing: AppSpacing.sm) {
                        StatBox(sfSymbol: "drop.fill", title: "Avg Oil", value: String(format: "%.1f", viewModel.averageOil))
                        StatBox(sfSymbol: "sun.dust", title: "Avg Dry", value: String(format: "%.1f", viewModel.averageDryness))
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                    HStack(spacing: AppSpacing.sm) {
                        StatBox(sfSymbol: "circle.fill", title: "Avg Red", value: String(format: "%.1f", viewModel.averageRedness))
                        StatBox(sfSymbol: "magnifyingglass", title: "Avg Acne", value: String(format: "%.1f", viewModel.averageAcne))
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)

                    // Recent Entries
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Recent Entries")
                            .font(.appSectionTitle)
                            .foregroundColor(.appTextPrimary)
                            .padding(.horizontal, AppSpacing.screenHorizontal)

                        if viewModel.allEntries.isEmpty {
                            Text("No entries yet.")
                                .foregroundColor(.appTextTertiary)
                                .font(.appBody)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(viewModel.allEntries) { entry in
                                EntryRow(entry: entry, viewModel: viewModel)
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                                Divider()
                                    .background(Color.appDivider)
                                    .padding(.leading, AppSpacing.screenHorizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, AppSpacing.screenVertical)
                .opacity(appeared ? 1 : 0)
            }
            .navigationTitle("Skin Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddEntry = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.appAccentPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView(viewModel: AddEntryViewModel(trackerManager: dependencies.trackerManager, dataManager: dependencies.dataManager), onSaved: {
                    viewModel.refresh()
                })
            }
            .onAppear {
                viewModel.refresh()
                if !reduceMotion {
                    withAnimation(DesignMotion.editorialSpring) {
                        appeared = true
                    }
                } else {
                    appeared = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct LegendItem: View {
    let name: String
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(name)
                .font(.appCaptionText)
                .foregroundColor(.appTextSecondary)
        }
    }
}

struct StatBox: View {
    let sfSymbol: String
    let title: String
    let value: String

    var body: some View {
        CardView {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: sfSymbol)
                    .font(.system(size: 20))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(.appAccentPrimary)

                Text(value)
                    .font(.appSectionTitle)
                    .foregroundColor(.appTextPrimary)

                Text(title)
                    .font(.appCaptionText)
                    .foregroundColor(.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct EntryRow: View {
    let entry: SkinEntry
    let viewModel: TrackerViewModel
    @State private var image: UIImage? = nil

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // SF Symbol for mood instead of emoji
            Image(systemName: entry.mood.sfSymbol)
                .font(.system(size: 20))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.appAccentPrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, style: .date)
                    .font(.appHeading3)
                    .foregroundColor(.appTextPrimary)

                Text("Oil \(entry.oilLevel) · Dry \(entry.drynessLevel) · Red \(entry.rednessLevel)")
                    .font(.appCaptionText)
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            if let photoName = entry.photoFileName {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.appBackgroundSecondary)
                        .frame(width: 40, height: 40)
                        .onAppear {
                            image = viewModel.loadPhoto(named: photoName)
                        }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                if let index = viewModel.allEntries.firstIndex(where: { $0.id == entry.id }) {
                    viewModel.deleteEntry(at: index)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
