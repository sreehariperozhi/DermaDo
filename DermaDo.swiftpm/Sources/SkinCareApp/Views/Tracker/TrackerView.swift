import SwiftUI
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

    var body: some View {
        ZStack {
            // MARK: - Background
            backgroundLayer

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: DesignSpacing.heroic) {
                    
                    // MARK: - Header
                    headerSection
                        .editorialReveal(delay: 0.1)

                    // MARK: - Period Selector
                    periodSelector
                        .editorialReveal(delay: 0.15)

                    // MARK: - Trends Chart
                    trendsChartSection
                        .editorialReveal(delay: 0.2)

                    // MARK: - Stats Grid
                    statsGridSection
                        .editorialReveal(delay: 0.25)

                    // MARK: - Recent Entries
                    recentEntriesSection
                        .editorialReveal(delay: 0.3)
                    
                    Spacer().frame(height: 100) // Clearance for floating dock
                }
                .padding(.horizontal, DesignSpacing.large)
                .padding(.top, DesignSpacing.editorial)
            }
        }
        .colorScheme(.dark)
        .onAppear {
            viewModel.refresh()
            withAnimation(DesignMotion.heroMaterialize) {
                appeared = true
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView(viewModel: AddEntryViewModel(trackerManager: dependencies.trackerManager, dataManager: dependencies.dataManager), onSaved: {
                viewModel.refresh()
            })
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

            // Velvet Crimson orb for irritation tracking context
            Circle()
                .fill(DesignColors.velvetCrimson.opacity(0.05))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 150, y: 150)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                Text("SKIN ANALYTICS")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)

                Text("Skin Tracker")
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.luminousPearl)
            }
            Spacer()
            
            Button(action: { showingAddEntry = true }) {
                ZStack {
                    Circle()
                        .fill(DesignColors.voidAsh.opacity(0.8))
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(DesignShadows.innerGlow, lineWidth: 1))
                    
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(DesignColors.roseGold)
                }
            }
        }
    }

    // MARK: - Period Selector
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TrackerViewModel.Period.allCases, id: \.self) { period in
                let isSelected = viewModel.selectedPeriod == period
                Button(action: {
                    withAnimation(DesignMotion.tactilePress) {
                        viewModel.selectedPeriod = period
                    }
                }) {
                    Text(period == .week ? "Week" : "Month")
                        .font(DesignTypography.bodyStrongUI)
                        .foregroundColor(isSelected ? DesignColors.voidObsidian : DesignColors.liquidSilver)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            Capsule()
                                .fill(isSelected ? DesignColors.luminousPearl : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(DesignColors.voidAsh.opacity(0.5))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(DesignShadows.innerGlow, lineWidth: 1))
    }

    // MARK: - Trends Chart
    private var trendsChartSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.standard) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(DesignColors.roseGold)
                Text("Trends")
                    .font(DesignTypography.titleUI)
                    .foregroundColor(DesignColors.luminousPearl)
                Spacer()
            }

            if !viewModel.periodEntries.isEmpty {
                Chart {
                    ForEach(viewModel.periodEntries) { entry in
                        // Oil Level
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Oil", entry.oilLevel)
                        )
                        .foregroundStyle(DesignColors.ceruleanHydration)
                        .interpolationMethod(.catmullRom)

                        // Dryness
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Dryness", entry.drynessLevel)
                        )
                        .foregroundStyle(DesignColors.roseGold)
                        .interpolationMethod(.catmullRom)

                        // Redness
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Redness", entry.rednessLevel)
                        )
                        .foregroundStyle(DesignColors.velvetCrimson)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 220)
                .chartYScale(domain: 0...10)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(DesignTypography.microUI)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(DesignColors.voidAsh)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(DesignTypography.microUI)
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(DesignColors.voidAsh)
                    }
                }
            } else {
                VStack(spacing: DesignSpacing.medium) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(DesignColors.voidAsh)
                    Text("No data for this period")
                        .font(DesignTypography.bodyUI)
                        .foregroundColor(DesignColors.liquidSilver)
                }
                .frame(height: 220)
                .frame(maxWidth: .infinity)
            }

            // Legend
            HStack(spacing: DesignSpacing.large) {
                legendItem(label: "Oil", color: DesignColors.ceruleanHydration)
                legendItem(label: "Dryness", color: DesignColors.roseGold)
                legendItem(label: "Redness", color: DesignColors.velvetCrimson)
            }
        }
        .padding(DesignSpacing.standard)
        .glassCard()
    }

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(DesignTypography.microUI)
                .foregroundColor(DesignColors.liquidSilver)
        }
    }

    // MARK: - Stats Grid
    private var statsGridSection: some View {
        VStack(spacing: DesignSpacing.medium) {
            HStack(spacing: DesignSpacing.medium) {
                StatCard(title: "AVG OIL", value: String(format: "%.1f", viewModel.averageOil), unit: "/10", icon: "drop.fill", color: DesignColors.ceruleanHydration)
                StatCard(title: "AVG DRY", value: String(format: "%.1f", viewModel.averageDryness), unit: "/10", icon: "sun.dust.fill", color: DesignColors.roseGold)
            }
            HStack(spacing: DesignSpacing.medium) {
                StatCard(title: "AVG RED", value: String(format: "%.1f", viewModel.averageRedness), unit: "/10", icon: "thermometer.high", color: DesignColors.velvetCrimson)
                StatCard(title: "AVG ACNE", value: String(format: "%.0f", viewModel.averageAcne), unit: "pts", icon: "face.dashed", color: DesignColors.sageBotanical)
            }
        }
    }

    // MARK: - Recent Entries
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.standard) {
            Text("Recent Logs")
                .font(DesignTypography.titleUI)
                .foregroundColor(DesignColors.luminousPearl)

            if viewModel.allEntries.isEmpty {
                Text("No entries yet.")
                    .font(DesignTypography.bodyUI)
                    .foregroundColor(DesignColors.liquidSilver)
            } else {
                VStack(spacing: DesignSpacing.small) {
                    ForEach(viewModel.allEntries.prefix(5)) { entry in
                        EntryCard(entry: entry, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

// MARK: - Subviews
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(DesignTypography.microUI)
                    .foregroundColor(DesignColors.liquidSilver)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(DesignColors.luminousPearl)
                Text(unit)
                    .font(DesignTypography.microUI)
                    .foregroundColor(DesignColors.voidAsh)
            }
        }
        .padding(DesignSpacing.standard)
        .glassCard()
    }
}

struct EntryCard: View {
    let entry: SkinEntry
    let viewModel: TrackerViewModel
    @State private var image: UIImage? = nil

    var body: some View {
        HStack(spacing: DesignSpacing.standard) {
            // Mood / Day
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, style: .date)
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(DesignColors.luminousPearl)
                Text(entry.mood.displayName)
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.liquidSilver)
            }
            
            Spacer()
            
            // Metrics Mini
            HStack(spacing: 8) {
                metricDot(val: entry.oilLevel, color: DesignColors.ceruleanHydration)
                metricDot(val: entry.drynessLevel, color: DesignColors.roseGold)
                metricDot(val: entry.rednessLevel, color: DesignColors.velvetCrimson)
            }
            
            // Photo Preview
            if let photoName = entry.photoFileName {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(DesignColors.voidAsh)
                        .frame(width: 44, height: 44)
                        .onAppear {
                            image = viewModel.loadPhoto(named: photoName)
                        }
                }
            }
        }
        .padding(DesignSpacing.standard)
        .glassCard()
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
    
    private func metricDot(val: Int, color: Color) -> some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: 1).frame(width: 14, height: 14)
            Circle().fill(color).frame(width: 4, height: 4)
        }
    }
}
