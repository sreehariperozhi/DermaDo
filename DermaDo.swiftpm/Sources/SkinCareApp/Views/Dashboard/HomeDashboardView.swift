import SwiftUI
import Charts

/// The central 2.0 Hub dashboard — luxury glassmorphism home screen
/// connected to real data from the app's manager layer.
public struct HomeDashboardView: View {
    @StateObject private var viewModel: HomeDashboardViewModel
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var dependencies: AppDependencies
    @EnvironmentObject private var activeSession: ActiveRoutineSession
    @EnvironmentObject private var voiceManager: VoiceManager
    
    @State private var showingAddRoutine = false
    @State private var showingRoutineSession = false
    @State private var showingTrendTooltip = false
    
    public init(viewModel: HomeDashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DesignSpacing.large) {
                
                // MARK: - 1. Header & Greeting
                headerSection
                
                // MARK: - 2. Next Routine Hero Card
                routineHeroCard
                
                // MARK: - 3. Skin Tracker Glance
                skinTrackerGlance
                
                // MARK: - 4. Consistency Streak
                streakCard
                
                // MARK: - 4b. Encouragement Message
                if !viewModel.encouragementMessage.isEmpty {
                    encouragementCard
                }
                
                // MARK: - 5. Next Reminder
                if let reminderText = viewModel.nextReminderText {
                    reminderCard(text: reminderText)
                }
                
                // Removed scroll clearance for floating tab bar
            }
            .padding(.horizontal, DesignSpacing.large)
            .padding(.top, DesignSpacing.standard)
        }
        .background(backgroundGradient)
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $showingAddRoutine) {
            RoutineDetailView(viewModel: RoutineDetailViewModel(
                routineManager: dependencies.routineManager,
                mode: .add
            ))
        }
        .fullScreenCover(isPresented: $showingRoutineSession) {
            if let routine = viewModel.todayRoutine {
                let filteredRoutine = Routine(
                    id: routine.id,
                    name: routine.name,
                    timeOfDay: routine.timeOfDay,
                    steps: routine.stepsForToday(),
                    repeatDays: routine.repeatDays,
                    isEnabled: routine.isEnabled,
                    notifyReminder: routine.notifyReminder,
                    reminderTime: routine.reminderTime,
                    createdAt: routine.createdAt,
                    updatedAt: routine.updatedAt
                )
                
                RoutineSessionView2(
                    routine: filteredRoutine,
                    productManager: dependencies.productManager,
                    progressManager: dependencies.progressManager,
                    trackerManager: dependencies.trackerManager,
                    activeSession: activeSession,
                    voiceManager: voiceManager
                )
            }
        }
    }
    
    // MARK: - Section 1: Header & Greeting
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                Text(viewModel.greetingText)
                    .font(DesignTypography.headerEditorial)
                    .foregroundColor(DesignColors.liquidSilver)
                    .editorialReveal(delay: 0.1)
                
                Text("Your skin dashboard")
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.luminousPearl)
                    .editorialReveal(delay: 0.2)
            }
            Spacer()
            
            // Profile indicator
            Circle()
                .fill(DesignColors.voidAsh)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "person")
                        .foregroundColor(DesignColors.liquidSilver)
                )
                .editorialReveal(delay: 0.3)
        }
    }
    
    // MARK: - Section 2: Next Routine Hero Card
    
    private var routineHeroCard: some View {
        VStack(alignment: .leading, spacing: DesignSpacing.standard) {
            if viewModel.hasRoutine {
                let isEnabled = viewModel.todayRoutine?.isEnabled ?? true
                
                // Header with Toggle
                HStack {
                    HStack(spacing: DesignSpacing.small) {
                        Text("UP NEXT / \(viewModel.nextRoutineTimeDesc)".uppercased())
                            .font(DesignTypography.captionUI)
                            .captionTracking()
                            .foregroundColor(DesignColors.ceruleanHydration)
                        
                        if !isEnabled {
                            Text("PAUSED")
                                .font(DesignTypography.microUI)
                                .captionTracking()
                                .foregroundColor(DesignColors.roseGold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignColors.roseGold.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { isEnabled },
                        set: { _ in
                            withAnimation(DesignMotion.editorialSpring) {
                                viewModel.toggleRoutineEnabled()
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(DesignColors.ceruleanHydration)
                    .scaleEffect(0.8)
                }
                
                VStack(alignment: .leading, spacing: DesignSpacing.standard) {
                    // Routine name
                    Text(viewModel.nextRoutineName)
                        .font(DesignTypography.titleUI)
                        .foregroundColor(DesignColors.luminousPearl)
                    
                    // Step count
                    HStack(spacing: DesignSpacing.small) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14))
                            .foregroundColor(DesignColors.liquidSilver)
                        Text("\(viewModel.nextRoutineStepCount) steps")
                            .font(DesignTypography.bodyUI)
                            .foregroundColor(DesignColors.liquidSilver)
                    }
                    
                    Spacer().frame(height: DesignSpacing.medium)
                    
                    Button(action: {
                        viewModel.startNextRoutine()
                        showingRoutineSession = true
                    }) {
                        Text("Start Routine")
                    }
                    .primaryButtonStyle()
                    .disabled(!isEnabled)
                    .opacity(isEnabled ? 1.0 : 0.6)
                }
                .opacity(isEnabled ? 1.0 : 0.5)
            } else {
                // Empty state
                VStack(spacing: DesignSpacing.standard) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 36))
                        .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
                    
                    Text("No routine scheduled")
                        .font(DesignTypography.titleUI)
                        .foregroundColor(DesignColors.luminousPearl)
                    
                    Button(action: {
                        showingAddRoutine = true
                    }) {
                        Text("Create Routine")
                    }
                    .primaryButtonStyle()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .editorialReveal(delay: 0.4)
    }
    
    // MARK: - Section 3: Skin Tracker Glance
    
    /// Shared height for dashboard metric cards
    private let dashboardCardHeight: CGFloat = 170
    
    private var skinTrackerGlance: some View {
        HStack(spacing: DesignSpacing.standard) {
            // Skin Score
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                Text("SKIN SCORE")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)
                Text(viewModel.lastSkinScore)
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.roseGold)
                
                Spacer(minLength: 0)
                
                scoreSparkline
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity, minHeight: dashboardCardHeight, alignment: .leading)
            .glassCard()
            
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                Text("TREND")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)
                
                HStack(spacing: DesignSpacing.micro) {
                    Image(systemName: viewModel.skinTrendStatus.icon)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(viewModel.skinTrendStatus.label)
                        .font(DesignTypography.bodyStrongUI)
                }
                .foregroundColor(trendColor)
            }
            .frame(maxWidth: .infinity, minHeight: dashboardCardHeight, alignment: .leading)
            .glassCard()
            .overlay(alignment: .top) {
                if showingTrendTooltip {
                    trendTooltip
                        .offset(y: -45)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity
                        ))
                }
            }
            .onTapGesture {
                withAnimation(DesignMotion.editorialSpring) {
                    showingTrendTooltip = true
                }
                // Auto-dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showingTrendTooltip = false
                    }
                }
            }
        }
        .editorialReveal(delay: 0.5)
    }
    
    private var trendColor: Color {
        switch viewModel.skinTrendStatus {
        case .improving: return DesignColors.sageBotanical
        case .declining: return DesignColors.velvetCrimson
        case .stable: return DesignColors.roseGold // Use roseGold for stable as it's premium
        case .unknown: return DesignColors.liquidSilver
        }
    }
    
    // MARK: - Tooltip
    
    private var trendTooltip: some View {
        Text("Trend compares your last 7 days average skin score.")
            .font(DesignTypography.microUI)
            .foregroundColor(DesignColors.luminousPearl)
            .padding(.horizontal, DesignSpacing.standard)
            .padding(.vertical, DesignSpacing.small)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
    }
    
    // MARK: - Sparkline
    
    private var scoreSparkline: some View {
        Group {
            if viewModel.scoreHistory.count >= 2 {
                Chart {
                    ForEach(Array(viewModel.scoreHistory.enumerated()), id: \.offset) { index, score in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Score", score)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(sparklineColor)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                        
                        AreaMark(
                            x: .value("Day", index),
                            y: .value("Score", score)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [sparklineColor.opacity(0.3), sparklineColor.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartYScale(domain: 0...10)
                .transition(.opacity)
                .animation(.easeIn(duration: 0.8), value: viewModel.scoreHistory)
            } else {
                // Not enough data for sparkline
                Color.clear
            }
        }
    }
    
    private var sparklineColor: Color {
        guard viewModel.scoreHistory.count >= 2 else { return DesignColors.liquidSilver }
        
        let scores = viewModel.scoreHistory
        let latest = scores.last!
        let previous = scores[scores.count - 2]
        let diff = latest - previous
        
        // Use a small threshold for "Stable" to avoid jitter for tiny changes
        if diff > 0.15 {
            return DesignColors.sageBotanical // Green (improving)
        } else if diff < -0.15 {
            return DesignColors.velvetCrimson // Red (declining)
        } else {
            return Color.orange.opacity(0.8) // Orange (stable)
        }
    }
    
    // MARK: - Section 4: Consistency Streak
    
    private var streakCard: some View {
        HStack(spacing: DesignSpacing.medium) {
            // Streak flame
            ZStack {
                Circle()
                    .fill(DesignColors.roseGold.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: viewModel.streakDays > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 26))
                    .foregroundColor(
                        viewModel.streakDays > 0
                            ? DesignColors.roseGold
                            : DesignColors.liquidSilver.opacity(0.5)
                    )
            }
            
            VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                Text("\(viewModel.streakDays)")
                    .font(DesignTypography.displayEditorial)
                    .foregroundColor(DesignColors.luminousPearl)
                
                Text("day streak · \(viewModel.totalEntries) total logs")
                    .font(DesignTypography.captionUI)
                    .foregroundColor(DesignColors.liquidSilver)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .editorialReveal(delay: 0.6)
    }
    
    // MARK: - Section 4b: Encouragement
    
    private var encouragementCard: some View {
        HStack(spacing: DesignSpacing.standard) {
            ZStack {
                Circle()
                    .fill(DesignColors.sageBotanical.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "sparkle")
                    .font(.system(size: 18))
                    .foregroundColor(DesignColors.sageBotanical)
            }
            
            Text(viewModel.encouragementMessage)
                .font(DesignTypography.bodyUI)
                .foregroundColor(DesignColors.luminousPearl)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .editorialReveal(delay: 0.65)
    }
    
    // MARK: - Section 5: Next Reminder
    
    private func reminderCard(text: String) -> some View {
        HStack(spacing: DesignSpacing.standard) {
            ZStack {
                Circle()
                    .fill(DesignColors.ceruleanHydration.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(DesignColors.ceruleanHydration)
            }
            
            VStack(alignment: .leading, spacing: DesignSpacing.micro) {
                Text("NEXT REMINDER")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)
                Text(text)
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(DesignColors.luminousPearl)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .editorialReveal(delay: 0.7)
    }
    
    // MARK: - Background Gradient
    
    private var backgroundGradient: some View {
        ZStack {
            DesignColors.voidObsidian.ignoresSafeArea()
            Circle()
                .fill(DesignColors.ceruleanHydration.opacity(0.15))
                .frame(width: 400, height: 400)
                .blur(radius: 120)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(DesignColors.roseGold.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: 150, y: 100)
        }
    }
}
