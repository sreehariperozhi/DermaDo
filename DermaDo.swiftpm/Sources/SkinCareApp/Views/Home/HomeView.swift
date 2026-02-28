import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dependencies: AppDependencies

    var body: some View {
         HomeViewContent(viewModel: HomeViewModel(
            routineManager: dependencies.routineManager,
            trackerManager: dependencies.trackerManager,
            settingsManager: dependencies.settingsManager
         ))
    }
}

// MARK: - HomeViewContent

struct HomeViewContent: View {
    @EnvironmentObject var dependencies: AppDependencies
    @StateObject var viewModel: HomeViewModel
    @State private var showingAddRoutine = false
    @State private var showingRoutineSession = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {

                    // 1. Greeting
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(viewModel.greetingText)
                            .font(.appLargeTitle)
                            .foregroundColor(.appTextPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Here's your skincare overview")
                            .font(.appBody)
                            .foregroundColor(.appTextSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, AppSpacing.lg)

                    // 2. Today's Routine Card
                    CardView {
                        VStack(spacing: AppSpacing.md) {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "leaf")
                                    .font(.system(size: 18))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appAccentPrimary)

                                Text(viewModel.hasRoutine ? (viewModel.todayRoutine?.name ?? "Today's Routine") : "Today's Routine")
                                    .font(.appSectionTitle)
                                    .foregroundColor(.appTextPrimary)

                                Spacer()
                            }

                            if viewModel.hasRoutine {
                                VStack(spacing: AppSpacing.sm) {
                                    ForEach(Array(viewModel.todaySteps.enumerated()), id: \.element.id) { index, step in
                                        StepRow(index: index + 1, step: step)
                                    }
                                }
                            } else {
                                VStack(spacing: AppSpacing.xs) {
                                    Image(systemName: "moon.stars")
                                        .font(.system(size: 28))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.appTextTertiary)

                                    Text("No routine scheduled for now.\nTap Routines to create one.")
                                        .font(.appBody)
                                        .foregroundColor(.appTextTertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, AppSpacing.md)
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }

                    // 3. Streak Card
                    CardView {
                        HStack(spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.appAccentSubtle)
                                    .frame(width: 52, height: 52)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 22))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundColor(.appAccentPrimary)
                            }

                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text("\(viewModel.streakDays)")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(.appTextPrimary)

                                Text("day streak")
                                    .font(.appBody)
                                    .foregroundColor(.appTextSecondary)
                            }
                            Spacer()
                        }
                    }

                    // 4. Reminder Card
                    if let reminderText = viewModel.nextReminderText {
                        CardView {
                            HStack(spacing: AppSpacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color.appAccentSubtle)
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "clock")
                                        .font(.system(size: 18))
                                        .symbolRenderingMode(.hierarchical)
                                        .foregroundColor(.appAccentPrimary)
                                }

                                Text(reminderText)
                                    .font(.appHeading3)
                                    .foregroundColor(.appTextPrimary)
                                Spacer()
                            }
                        }
                    }

                    // 5. Quick Start Button
                    PrimaryButton(
                        title: viewModel.hasRoutine ? "Start Routine" : "Create Routine",
                        action: {
                            if viewModel.hasRoutine {
                                showingRoutineSession = true
                            } else {
                                showingAddRoutine = true
                            }
                        }
                    )
                    .padding(.top, AppSpacing.xs)

                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
            }
            .background(Color.appBackgroundPrimary.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
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
            .sheet(isPresented: $showingAddRoutine) {
                RoutineDetailView(viewModel: RoutineDetailViewModel(routineManager: viewModel.routineManager, mode: .add))
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
                        activeSession: ActiveRoutineSession(),
                        voiceManager: VoiceManager()
                    )
                }
            }
        }
    }
}

// MARK: - StepRow

struct StepRow: View {
    let index: Int
    let step: RoutineStep

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.appAccentSubtle)
                    .frame(width: 26, height: 26)

                Text("\(index)")
                    .font(.appNumericSmall)
                    .foregroundColor(.appAccentPrimary)
            }

            Text(step.instruction.isEmpty ? step.stepType.rawValue.capitalized : step.instruction)
                .font(.appBody)
                .foregroundColor(.appTextPrimary)

            Spacer()
        }
        .frame(height: 34)
    }
}
