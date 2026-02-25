import SwiftUI

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
    
    public init(viewModel: HomeDashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DesignSpacing.heroic) {
                
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
                
                Spacer().frame(height: 100) // Scroll clearance for floating tab bar
            }
            .padding(.horizontal, DesignSpacing.large)
            .padding(.top, DesignSpacing.editorial)
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
                RoutineSessionView2(
                    routine: routine,
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
                // Label
                Text("UP NEXT / \(viewModel.nextRoutineTimeDesc)".uppercased())
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.ceruleanHydration)
                
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
            } else {
                // Empty state
                VStack(spacing: DesignSpacing.standard) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 36))
                        .foregroundColor(DesignColors.liquidSilver.opacity(0.5))
                    
                    Text("No routine scheduled")
                        .font(DesignTypography.titleUI)
                        .foregroundColor(DesignColors.luminousPearl)
                    
                    Text("Create one to get started with your skincare journey.")
                        .font(DesignTypography.bodyUI)
                        .foregroundColor(DesignColors.liquidSilver)
                        .multilineTextAlignment(.center)
                    
                    Spacer().frame(height: DesignSpacing.small)
                    
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
            
            // Trend
            VStack(alignment: .leading, spacing: DesignSpacing.small) {
                Text("TREND")
                    .font(DesignTypography.captionUI)
                    .captionTracking()
                    .foregroundColor(DesignColors.liquidSilver)
                Text(viewModel.skinTrend)
                    .font(DesignTypography.bodyStrongUI)
                    .foregroundColor(trendColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassCard()
        }
        .editorialReveal(delay: 0.5)
    }
    
    /// Returns the appropriate color for the current skin trend
    private var trendColor: Color {
        if viewModel.skinTrend.contains("Improving") {
            return DesignColors.sageBotanical
        } else if viewModel.skinTrend.contains("attention") {
            return DesignColors.velvetCrimson
        } else {
            return DesignColors.liquidSilver
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
